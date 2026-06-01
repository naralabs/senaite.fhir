FHIR ServiceRequest Revoke
--------------------------

Exercise the ``ServiceRequest/$revoke`` operation exposed by the FHIR API
route ``/senaite/@@FHIR/r5/ServiceRequest/<uid>/$revoke``.

The operation maps the FHIR revoke onto SENAITE's sample workflow: it
applies the ``reject`` transition when the rejection workflow is enabled
and a reason is supplied, and falls back to ``cancel`` otherwise. On
success it returns a ``SenaiteServiceRequestRevoked`` ServiceRequest with
``status`` fixed to ``revoked``; when the underlying sample cannot be
revoked it returns a ``SenaiteServiceRequestRevocationError``
OperationOutcome.

See the implementation guide for the workflow description:
https://fhir.senaite.org/lab-request-and-results.html#secondary-workflow-revoke-lab-request

Running this test from the buildout directory:

    bin/test test_doctests -t servicerequest_revoke


Test Setup
~~~~~~~~~~

Needed imports:

    >>> import json
    >>> import transaction
    >>> from DateTime import DateTime
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from bika.lims import api
    >>> from bika.lims.utils.analysisrequest import create_analysisrequest

Functional helpers:

    >>> def revoke(uid, body, resource_type="ServiceRequest"):
    ...     url = "{}/{}/{}/$revoke".format(fhir_url, resource_type, uid)
    ...     browser.post(url, json.dumps(body), content_type="application/json")
    ...     return json.loads(browser.contents)

    >>> def status_code():
    ...     return int(browser.headers["Status"].split(" ", 1)[0])

A ``Parameters`` body carrying an optional revoke ``reason``:

    >>> def parameters(*reasons):
    ...     params = [{"name": "reason", "valueString": r} for r in reasons]
    ...     return {"resourceType": "Parameters", "parameter": params}

Variables:

    >>> portal = self.portal
    >>> request = self.request
    >>> setup = portal.setup
    >>> portal_url = portal.absolute_url()
    >>> fhir_url = "{}/@@FHIR/r5".format(portal_url)
    >>> browser = self.getBrowser()
    >>> browser.raiseHttpErrors = False
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])


Setup objects
~~~~~~~~~~~~~

Create the minimum set of objects needed to register a sample:

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Happy Hills", ClientID="HH")
    >>> contact = api.create(client, "Contact",
    ...                      Firstname="Rita", Lastname="Mohale")
    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Water", Prefix="W")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Boss")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Chemistry", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="Metals", Department=department)
    >>> Cu = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Copper", Keyword="Cu",
    ...                 Category=category.UID())

A helper that registers a fresh sample (``sample_due`` state):

    >>> def new_sample():
    ...     values = {
    ...         "Client": client.UID(),
    ...         "Contact": contact.UID(),
    ...         "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...         "SampleType": sampletype.UID(),
    ...     }
    ...     sample = create_analysisrequest(client, request, values, [Cu.UID()])
    ...     transaction.commit()
    ...     return sample


Revoke via the cancel path
~~~~~~~~~~~~~~~~~~~~~~~~~~~

With the rejection workflow disabled (the default), a freshly registered
sample can only be ``cancel``-ed, so ``$revoke`` resolves to that
transition. A ``Parameters`` body is required even when no reason is
supplied:

    >>> sample = new_sample()
    >>> api.get_workflow_status_of(sample)
    'sample_due'

    >>> uid = api.get_uid(sample)
    >>> resource = revoke(uid, parameters())
    >>> status_code()
    200

The response is a ServiceRequest whose status is ``revoked``:

    >>> resource["resourceType"]
    u'ServiceRequest'
    >>> resource["status"]
    u'revoked'

Its logical id is the sample UID and the metadata confirms the update was
applied:

    >>> import uuid
    >>> uuid.UUID(resource["id"]).hex == uid
    True
    >>> "versionId" in resource["meta"]
    True
    >>> "lastUpdated" in resource["meta"]
    True

The underlying sample has been cancelled:

    >>> api.get_workflow_status_of(sample)
    'cancelled'


Revoke via the reject path with a reason
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the rejection workflow is enabled both ``reject`` and ``cancel``
become available; supplying a reason makes ``$revoke`` resolve to
``reject``. The reason is matched (case-insensitively) against the
predefined rejection reasons of the setup:

    >>> setup.setEnableRejectionWorkflow(True)
    >>> setup.setRejectionReasons([u"Insufficient sample", u"Broken seal"])
    >>> transaction.commit()

    >>> sample = new_sample()
    >>> uid = api.get_uid(sample)
    >>> resource = revoke(uid, parameters(u"insufficient sample"))
    >>> status_code()
    200

    >>> resource["status"]
    u'revoked'

The matched reason is carried over as a plain-text note on the response:

    >>> resource["note"]
    [{u'text': u'Insufficient sample'}]

The sample has been rejected (not cancelled) and the reason was stored as
a SENAITE rejection reason:

    >>> api.get_workflow_status_of(sample)
    'rejected'
    >>> reasons = sample.getRejectionReasons()
    >>> reasons[0]["selected"]
    [u'Insufficient sample']

An unrecognised reason is kept verbatim under ``other``:

    >>> sample = new_sample()
    >>> resource = revoke(api.get_uid(sample), parameters(u"Lost in transit"))
    >>> status_code()
    200
    >>> sample.getRejectionReasons()[0]["other"]
    'Lost in transit'
    >>> resource["note"]
    [{u'text': u'Lost in transit'}]


Revoke is rejected when the transition is not allowed
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A sample that has already been revoked can neither be rejected nor
cancelled, so a second ``$revoke`` fails with an OperationOutcome:

    >>> resource = revoke(api.get_uid(sample), parameters())
    >>> status_code()
    403

The body is an OperationOutcome whose issue list flags the offending
element:

    >>> resource["resourceType"]
    u'OperationOutcome'

    >>> issue = resource["issue"][0]
    >>> issue["severity"]
    u'error'
    >>> issue["code"]
    u'forbidden'
    >>> issue["expression"]
    [u'ServiceRequest.status']
    >>> bool(issue["details"]["text"])
    True


Error handling
~~~~~~~~~~~~~~

An unknown UID is not found:

    >>> resource = revoke("00000000000000000000000000000000", parameters())
    >>> status_code()
    404
    >>> resource["success"]
    False

The UID must resolve to an object that matches the requested resource
type. Revoking a non-sample object through ``ServiceRequest`` is rejected
with ``406 Not Acceptable``:

    >>> resource = revoke(api.get_uid(client), parameters())
    >>> status_code()
    406
    >>> "Unexpected content type: Client" in resource["message"]
    True

The body must be a ``Parameters`` resource; a ServiceRequest payload is
not a valid revocation resource:

    >>> sample = new_sample()
    >>> uid = api.get_uid(sample)
    >>> bad_body = {"resourceType": "ServiceRequest", "id": str(uuid.UUID(uid))}
    >>> resource = revoke(uid, bad_body)
    >>> status_code()
    500
    >>> "Not a ServiceRevocationResource" in resource["message"]
    True
