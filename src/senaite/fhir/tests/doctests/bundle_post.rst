FHIR Bundle POST (lab request)
------------------------------

Exercise the POST endpoint of the FHIR API route ``/senaite/@@FHIR/r5``
with a ``SenaiteRequestBundle`` (a transaction ``Bundle``). Posting the
bundle registers a new lab request: the underlying SENAITE objects are
derived from the FHIR resources it carries.

The example bundle is the one published in the implementation guide:
https://fhir.senaite.org/Bundle-cafa2ba8-7aad-5d5e-b2c4-752f61f6ec8f.json

It carries a ``Patient``, an ``Organization`` (the submitting Client), a
``Practitioner`` (the requester), a ``Specimen`` and a ``ServiceRequest``.
The ``Client`` must already exist in SENAITE; everything else (Patient,
Practitioner -> Contact and the ServiceRequest -> AnalysisRequest) is
created automatically.

See https://fhir.senaite.org/StructureDefinition-SenaiteRequestBundle.html
and https://fhir.senaite.org/lab-request-and-results.html

Running this test from the buildout directory:

    bin/test test_doctests -t bundle_post


Test Setup
~~~~~~~~~~

Needed imports:

    >>> import json
    >>> import transaction
    >>> from pkg_resources import resource_string
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from bika.lims import api
    >>> from senaite.fhir import api as fapi

Variables:

    >>> portal = self.portal
    >>> request = self.request
    >>> setup = portal.setup
    >>> portal_url = portal.absolute_url()
    >>> fhir_url = "{}/@@FHIR/r5".format(portal_url)
    >>> browser = self.getBrowser()
    >>> browser.raiseHttpErrors = False
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])

Load the example bundle from the test data:

    >>> raw = resource_string("senaite.fhir.tests", "data/Bundle.01.json")
    >>> bundle = json.loads(raw)
    >>> bundle["resourceType"]
    u'Bundle'
    >>> bundle["type"]
    u'transaction'


Setup objects
~~~~~~~~~~~~~

Only the ``Client`` must pre-exist. The bundle's ``Organization`` is resolved
to it by the ``ClientFinder`` (an ``IContentFinder`` adapter): it matches on
the Organization's external identifier (the Client's ``ClientID``) and falls
back to the title, so the Organization is *updated* rather than created anew:

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Royal Melbourne Hospital",
    ...                     ClientID="ORG-RMH-MEL")

The ``SampleType`` is matched by the specimen's SNOMED display
(``Serum specimen``), so it must exist too:

    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Serum specimen", Prefix="SER")

The analysis services are matched by the LOINC codes carried in the
ServiceRequest ``orderDetail`` (here through their ``ProtocolID``):

    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Boss")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Chemistry", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="Liver", Department=department)

    >>> loinc_codes = ["1742-6", "1920-8", "6768-6", "1975-2",
    ...                "1968-7", "2885-2", "1751-7", "5902-2"]
    >>> for num, code in enumerate(loinc_codes):
    ...     service = api.create(
    ...         portal.bika_setup.bika_analysisservices, "AnalysisService",
    ...         title="LFT %s" % code, Keyword="LFT%s" % num,
    ...         Category=category.UID(), ProtocolID=code)
    >>> transaction.commit()


Post the bundle
~~~~~~~~~~~~~~~

    >>> browser.post("{}/Bundle".format(fhir_url), json.dumps(bundle),
    ...              content_type="application/json")
    >>> response = json.loads(browser.contents)

The response is a ``transaction-response`` Bundle:

    >>> response["resourceType"]
    u'Bundle'
    >>> response["type"]
    u'transaction-response'

It carries one entry per processed resource. The ``Specimen`` is not a
supported content type, so it is skipped; the remaining four are reported:

    >>> entries = response["entry"]
    >>> sorted([e["fullUrl"].split("/")[0] for e in entries])
    [u'Organization', u'Patient', u'Practitioner', u'ServiceRequest']

The pre-existing Client (Organization) is updated, the rest are created:

    >>> status = dict((e["fullUrl"].split("/")[0], e["response"]["status"])
    ...               for e in entries)
    >>> status["Organization"]
    u'201 Updated'
    >>> status["Patient"]
    u'201 Created'
    >>> status["Practitioner"]
    u'201 Created'
    >>> status["ServiceRequest"]
    u'201 Created'


Created content
~~~~~~~~~~~~~~~

Pick up the objects committed by the request:

    >>> portal._p_jar.sync()

A Patient was created (Patient is dexterity content, so we filter the
folder contents by portal type rather than meta type):

    >>> patients = [obj for obj in portal.patients.objectValues()
    ...             if api.get_portal_type(obj) == "Patient"]
    >>> len(patients)
    1

A Contact (from the Practitioner) was created under the existing Client,
and no new Client was added:

    >>> len(portal.clients.objectValues("Client"))
    1
    >>> contacts = [obj for obj in client.objectValues()
    ...             if api.get_portal_type(obj) == "Contact"]
    >>> len(contacts)
    1
    >>> contact = contacts[0]
    >>> contact.getFullname()
    'Catherine Sullivan'

A Sample (AnalysisRequest) was created under the Client from the
ServiceRequest:

    >>> samples = client.objectValues("AnalysisRequest")
    >>> len(samples)
    1
    >>> sample = samples[0]
    >>> api.get_workflow_status_of(sample)
    'sample_due'

It is wired to the resolved Client, Contact and SampleType:

    >>> sample.getClient() == client
    True
    >>> sample.getContact() == contact
    True
    >>> sample.getSampleType() == sampletype
    True

The eight ordered services were resolved into analyses:

    >>> len(sample.getAnalyses())
    8

The Patient created from the bundle carries its medical record number:

    >>> patients[0].getMRN()
    'MRN-20394857'
    >>> patients[0].getMaritalStatus()
    u'M'

The Patient telecom is mapped onto the patient record:

    >>> patients[0].getPhone()
    '+61 3 9000 1234'

The patient demographics from the bundle are also copied onto the Sample.
The public accessors (``getMedicalRecordNumberValue`` etc.) are guarded by
senaite.patient's ``@check_installed``, which requires the senaite.patient
browser layer on the *current* request -- not present in this test thread
after the POST -- so we read the stored field values directly:

    >>> sample.getField("MedicalRecordNumber").get(sample).get("value")
    'MRN-20394857'

    >>> sample.getField("PatientFullName").get_fullname(sample)
    'James Nguyen'

    >>> sample.getField("Sex").get(sample)
    'm'


Re-post the same Bundle (idempotent update)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Posting the same Bundle again resolves every resource to its existing
counterpart and updates it in place, instead of creating duplicates. We
tweak the ServiceRequest priority (``routine`` -> ``stat``) to observe that
the change is propagated to the Sample. The Sample is currently routine::

    >>> sample.getPriority()
    '5'

Bump the priority on the same ServiceRequest and re-post the Bundle::

    >>> service_request = [e["resource"] for e in bundle["entry"]
    ...                    if e["resource"]["resourceType"] == "ServiceRequest"][0]
    >>> service_request["priority"] = "stat"
    >>> browser.post("{}/Bundle".format(fhir_url), json.dumps(bundle),
    ...              content_type="application/json")
    >>> response = json.loads(browser.contents)

The same four resources are reported, now consistently as updated::

    >>> entries = response["entry"]
    >>> sorted([e["fullUrl"].split("/")[0] for e in entries])
    [u'Organization', u'Patient', u'Practitioner', u'ServiceRequest']

    >>> sorted(set(e["response"]["status"] for e in entries))
    [u'201 Updated']

No duplicates are created -- it is still the same Sample, now ``stat``::

    >>> portal._p_jar.sync()
    >>> samples = client.objectValues("AnalysisRequest")
    >>> len(samples)
    1
    >>> fapi.get_uid(samples[0]) == fapi.get_uid(sample)
    True
    >>> samples[0].getPriority()
    '1'


Update a manually-created counterpart (matched by MRN)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A counterpart need not have been created through the FHIR layer to be
updated: when there is no FHIR-UID match, the ``IContentFinder`` adapter
resolves it by a business key. ``PatientFinder`` matches a Patient by its
medical record number. Create a Patient manually first::

    >>> manual = api.create(portal.patients, "Patient", mrn=u"MRN-MANUAL",
    ...                     firstname=u"Manual", lastname=u"Patient")
    >>> transaction.commit()
    >>> before = len([obj for obj in portal.patients.objectValues()
    ...               if api.get_portal_type(obj) == "Patient"])

Post a Patient resource carrying a *different* logical id but the same MRN,
so it can only be matched by MRN (not by FHIR UID)::

    >>> incoming = {
    ...     "resourceType": "Patient",
    ...     "id": "bbbbbbbb-bbbb-5bbb-9bbb-bbbbbbbbbbbb",
    ...     "name": [{"use": "official", "family": "Patient",
    ...               "given": ["Manual"]}],
    ...     "telecom": [{"system": "phone",
    ...                  "value": "+61 3 9444 5555",
    ...                  "use": "home"}],
    ...     "gender": "male",
    ...     "birthDate": "1970-01-01",
    ...     "identifier": [{"use": "secondary", "value": "MRN-MANUAL"}],
    ... }
    >>> browser.post("{}/Patient".format(fhir_url), json.dumps(incoming),
    ...              content_type="application/json")
    >>> response = json.loads(browser.contents)

The existing Patient is matched and updated, not duplicated::

    >>> entries = response["entry"]
    >>> entries[0]["fullUrl"].split("/")[0]
    u'Patient'
    >>> entries[0]["response"]["status"]
    u'201 Updated'

    >>> portal._p_jar.sync()
    >>> after = len([obj for obj in portal.patients.objectValues()
    ...              if api.get_portal_type(obj) == "Patient"])
    >>> after == before
    True

It is now linked to the posted resource's FHIR id, so resolving by that id
returns the same manually-created Patient::

    >>> match = fapi.get_object_by_fhir_uid(
    ...     "bbbbbbbb-bbbb-5bbb-9bbb-bbbbbbbbbbbb", "Patient")
    >>> fapi.get_uid(match) == fapi.get_uid(manual)
    True
    >>> match.getPhone()
    '+61 3 9444 5555'
