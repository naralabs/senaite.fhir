FHIR DiagnosticReport Read
--------------------------

Verify that a ``ResultsReport`` (SENAITE's PDF report object) is exposed by
the FHIR API route ``/senaite/@@FHIR/r5/DiagnosticReport/<uid>`` and that
its JSON representation contains the expected FHIR DiagnosticReport fields.

Running this test from the buildout directory:

    bin/test test_doctests -t diagnosticreport_read


Test Setup
~~~~~~~~~~

Needed imports:

    >>> import json
    >>> import uuid
    >>> import transaction
    >>> from DateTime import DateTime
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from bika.lims import api
    >>> from bika.lims.utils.analysisrequest import create_analysisrequest
    >>> from bika.lims.workflow import doActionFor as do_action_for

Variables:

    >>> portal = self.portal
    >>> request = self.request
    >>> setup = portal.setup
    >>> portal_url = portal.absolute_url()
    >>> fhir_url = "{}/@@FHIR/r5".format(portal_url)
    >>> browser = self.getBrowser()
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])
    >>> portal.bika_setup.setSelfVerificationEnabled(True)
    >>> transaction.commit()


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


Create the Sample
~~~~~~~~~~~~~~~~~

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample = create_analysisrequest(client, request, values, [Cu.UID()])
    >>> sample
    <AnalysisRequest at /plone/clients/...>
    >>> sample_uid = api.get_uid(sample)
    >>> sample_id = api.get_id(sample)


Publish the Sample
~~~~~~~~~~~~~~~~~~

Transition the sample through the normal workflow so the report represents
a published request:

    >>> do_action_for(sample, "receive")[0]
    True
    >>> analyses = sample.getAnalyses(full_objects=True)
    >>> for analysis in analyses:
    ...     analysis.setResult(13)
    ...     _ = do_action_for(analysis, "submit")
    ...     _ = do_action_for(analysis, "verify")
    >>> api.get_workflow_status_of(sample)
    'verified'
    >>> do_action_for(sample, "publish")[0]
    True
    >>> api.get_workflow_status_of(sample)
    'published'


Create the ResultsReport
~~~~~~~~~~~~~~~~~~~~~~~~

A ``ResultsReport`` is the SENAITE content object that maps to a FHIR
``DiagnosticReport``. It lives inside the sample and holds a reference
back to the primary sample:

    >>> report = api.create(
    ...     sample, "ResultsReport",
    ...     sample=sample.UID(),
    ... )
    >>> report.setPdf({
    ...     "data": b"%PDF-1.4 fake diagnostic report",
    ...     "filename": u"HH-report.pdf",
    ...     "contentType": "application/pdf",
    ... })
    >>> report
    <ResultsReport at /plone/clients/...>
    >>> report_uid = api.get_uid(report)
    >>> transaction.commit()


Fetch via the FHIR Route
~~~~~~~~~~~~~~~~~~~~~~~~

Calling ``/senaite/@@FHIR/r5/DiagnosticReport/<uid>`` returns the FHIR
representation of the ResultsReport:

    >>> browser.open("{}/DiagnosticReport/{}".format(fhir_url, report_uid))
    >>> resource = json.loads(browser.contents)

The resource type is ``DiagnosticReport``:

    >>> resource["resourceType"]
    u'DiagnosticReport'

The logical ``id`` in the response corresponds to the report's UID:

    >>> uuid.UUID(resource["id"]).hex == report_uid
    True

The resource carries FHIR metadata with at least ``lastUpdated`` and
``profile``:

    >>> "meta" in resource
    True
    >>> "lastUpdated" in resource["meta"]
    True
    >>> "profile" in resource["meta"]
    True

The published sample maps to a FHIR ``final`` DiagnosticReport status:

    >>> api.get_review_status(sample)
    'published'
    >>> resource["status"]
    u'final'

The ``identifier`` list carries at least one entry whose ``value``
matches the sample's internal ID:

    >>> identifiers = resource["identifier"]
    >>> any(i.get("value") == sample_id for i in identifiers)
    True

The ``basedOn`` list contains a single reference that points back to the
parent sample as a ``ServiceRequest``:

    >>> based_on = resource["basedOn"]
    >>> len(based_on)
    1
    >>> based_on[0]["type"]
    u'ServiceRequest'

The reference's UID segment resolves to the same sample:

    >>> ref_uid = based_on[0]["reference"].split("/")[-1]
    >>> uuid.UUID(ref_uid).hex == sample_uid
    True

The ``result`` list contains one ``Observation`` reference per reportable
analysis. After publishing, the Copper analysis is reportable, so exactly
one entry is present:

    >>> result = resource["result"]
    >>> len(result)
    1
    >>> result[0]["reference"].startswith("Observation/")
    True
    >>> result[0]["display"]
    u'Copper'

The ``presentedForm`` list carries the base64-encoded PDF that was
attached to the report:

    >>> presented_form = resource["presentedForm"]
    >>> len(presented_form)
    1
    >>> presented_form[0]["contentType"]
    u'application/pdf'
    >>> presented_form[0]["title"]
    u'HH-report.pdf'


Fetch by UID Alone
~~~~~~~~~~~~~~~~~~

The same DiagnosticReport is also reachable via the plain UID segment,
without the resource-type prefix:

    >>> browser.open("{}/{}".format(fhir_url, report_uid))
    >>> json.loads(browser.contents)["resourceType"]
    u'DiagnosticReport'
