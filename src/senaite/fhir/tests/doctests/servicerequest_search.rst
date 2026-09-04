FHIR ServiceRequest Search
--------------------------

Verify that ``GET /senaite/@@FHIR/r5/ServiceRequest`` (the instrument
polling endpoint) returns a FHIR ``Bundle`` of type ``searchset`` containing
the instrument-scoped ``SenaiteInstrumentServiceRequest`` resources derived
from Analyses that are currently assigned to an Instrument (via
``AnalysisToInstrumentServiceRequest``).

The endpoint only supports the fixed query ``intent=filler-order`` and
``status=active``; it also supports ``_lastUpdated``, ``_sort=lastUpdated``
(the only supported value, and the default), and ``_count``/``_offset``
pagination.

Running this test from the buildout directory:

    bin/test test_doctests -t servicerequest_search


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
    >>> from senaite.fhir import api as fapi
    >>> from senaite.fhir.converter import to_fhir_datetime

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

Create the minimum set of objects to register samples and assign
Instruments to their Analyses:

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Metro Lab", ClientID="ML")
    >>> contact = api.create(client, "Contact",
    ...                      Firstname="Sam", Lastname="Lee")
    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Whole Blood", Prefix="WB")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Chief")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Haematology", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="CBC", Department=department)
    >>> Hb = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Haemoglobin", Keyword="Hb",
    ...                 Category=category.UID())
    >>> instr_type = api.create(setup.instrumenttypes, "InstrumentType",
    ...                         title=u"Haematology Analyser")
    >>> instrument = api.create(portal.bika_setup.bika_instruments,
    ...                        "Instrument", title=u"Sysmex XN-1000",
    ...                        InstrumentType=instr_type)
    >>> transaction.commit()

A helper that registers a fresh sample with one Hb Analysis and assigns it
to the Instrument. Assigning the Instrument goes through the
``setInstrument`` monkey patch, which links a ``SenaiteInstrumentServiceRequest``
identity and stamps ``authoredOn`` to "now"; the helper then backdates
``authoredOn`` in place by the given number of days so ordering can be
verified:

    >>> def new_linked_analysis(days_ago=0, mrn=None):
    ...     values = {
    ...         "Client": client.UID(),
    ...         "Contact": contact.UID(),
    ...         "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...         "SampleType": sampletype.UID(),
    ...     }
    ...     if mrn:
    ...         values["MedicalRecordNumber"] = {
    ...             "temporary": False, "value": mrn
    ...         }
    ...     sample = create_analysisrequest(client, request, values, [Hb.UID()])
    ...     analysis = sample.getAnalyses(full_objects=True)[0]
    ...     analysis.setInstrument(instrument)
    ...     storage = fapi.get_fhir_storage(analysis)
    ...     data = storage.get("data")
    ...     data["authoredOn"] = to_fhir_datetime(DateTime() - days_ago)
    ...     storage["data"] = data
    ...     transaction.commit()
    ...     return analysis


Missing/invalid required query parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``intent=filler-order`` is required:

    >>> browser.open("{}/ServiceRequest".format(fhir_url))
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["resourceType"]
    u'OperationOutcome'
    >>> outcome["issue"][0]["expression"]
    [u'intent']

    >>> browser.open("{}/ServiceRequest?intent=order".format(fhir_url))
    >>> browser.headers["Status"]
    '400 Bad Request'

``status=active`` is required once ``intent`` is satisfied:

    >>> browser.open(
    ...     "{}/ServiceRequest?intent=filler-order".format(fhir_url))
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["expression"]
    [u'status']

    >>> url = "{}/ServiceRequest?intent=filler-order&status=completed".format(
    ...     fhir_url)
    >>> browser.open(url)
    >>> browser.headers["Status"]
    '400 Bad Request'

Only ``_sort=lastUpdated`` is accepted:

    >>> url = ("{}/ServiceRequest?intent=filler-order&status=active"
    ...        "&_sort=-authoredOn").format(fhir_url)
    >>> browser.open(url)
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["expression"]
    [u'_sort']

Negative ``_count``/``_offset`` are rejected:

    >>> url = ("{}/ServiceRequest?intent=filler-order&status=active"
    ...        "&_count=-1").format(fhir_url)
    >>> browser.open(url)
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["expression"]
    [u'_count', u'_offset']


Empty bundle when nothing is linked yet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> base_url = "{}/ServiceRequest?intent=filler-order&status=active".format(
    ...     fhir_url)
    >>> browser.open(base_url)
    >>> browser.headers["Status"]
    '200 OK'
    >>> bundle = json.loads(browser.contents)
    >>> bundle["resourceType"]
    u'Bundle'
    >>> bundle["type"]
    u'searchset'
    >>> bundle["total"]
    0
    >>> "T" in bundle["timestamp"] and bundle["timestamp"][-6] in "+-"
    True
    >>> "entry" in bundle
    False


Populate linked Analyses
~~~~~~~~~~~~~~~~~~~~~~~~~

Create three Instrument-linked Analyses, backdated so their ``authoredOn``
values are strictly decreasing (most recent first):

    >>> newest = new_linked_analysis(days_ago=0)
    >>> middle = new_linked_analysis(days_ago=1)
    >>> oldest = new_linked_analysis(days_ago=2)

An Analysis that was never linked to an Instrument (no ``ServiceRequest``
FHIR identity) does not appear in the listing:

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> unlinked_sample = create_analysisrequest(
    ...     client, request, values, [Hb.UID()])
    >>> transaction.commit()


GET /ServiceRequest returns the linked ServiceRequests, newest first
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open(base_url)
    >>> bundle = json.loads(browser.contents)
    >>> bundle["total"]
    3

    >>> entries = bundle["entry"]
    >>> all(e["search"]["mode"] == "match" for e in entries)
    True
    >>> all(e["resource"]["resourceType"] == "ServiceRequest" for e in entries)
    True

Entries are ordered by ``authoredOn`` descending (most recently authored
first):

    >>> expected_order = [
    ...     "ServiceRequest/{}".format(fapi.get_fhir_id(a, "ServiceRequest"))
    ...     for a in (newest, middle, oldest)
    ... ]
    >>> [e["fullUrl"] for e in entries] == expected_order
    True


_count/_offset pagination
~~~~~~~~~~~~~~~~~~~~~~~~~~

Requesting one page at a time returns the expected slices and ``next``/
``previous`` links:

    >>> page1_url = base_url + "&_count=2&_offset=0"
    >>> browser.open(page1_url)
    >>> page1 = json.loads(browser.contents)
    >>> page1["total"]
    3
    >>> len(page1["entry"])
    2
    >>> [e["fullUrl"] for e in page1["entry"]] == expected_order[:2]
    True

    >>> relations = [link["relation"] for link in page1["link"]]
    >>> "self" in relations
    True
    >>> "next" in relations
    True
    >>> "previous" in relations
    False

    >>> page2_url = base_url + "&_count=2&_offset=2"
    >>> browser.open(page2_url)
    >>> page2 = json.loads(browser.contents)
    >>> len(page2["entry"])
    1
    >>> [e["fullUrl"] for e in page2["entry"]] == expected_order[2:]
    True

    >>> relations2 = [link["relation"] for link in page2["link"]]
    >>> "next" in relations2
    False
    >>> "previous" in relations2
    True


_lastUpdated filtering
~~~~~~~~~~~~~~~~~~~~~~~

``_lastUpdated`` filters by the underlying Analysis' modification date. A
threshold far in the past includes all three:

    >>> url = base_url + "&_lastUpdated=gt2000-01-01T00:00:00Z"
    >>> browser.open(url)
    >>> json.loads(browser.contents)["total"]
    3

A threshold far in the future excludes all of them:

    >>> url = base_url + "&_lastUpdated=gt2099-12-31T00:00:00Z"
    >>> browser.open(url)
    >>> future_bundle = json.loads(browser.contents)
    >>> future_bundle["total"]
    0
    >>> "entry" in future_bundle
    False

A malformed ``_lastUpdated`` value returns a ``400`` OperationOutcome:

    >>> url = base_url + "&_lastUpdated=not-a-date"
    >>> browser.open(url)
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["expression"]
    [u'_lastUpdated']


_include=Patient:subject adds Patient entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Register a Patient and link it (via MRN) to a fresh Instrument-linked
Analysis, which becomes the most recently authored one:

    >>> patient = api.create(
    ...     portal.patients, "Patient",
    ...     mrn=u"MRN-0001",
    ...     firstname=u"Jane",
    ...     lastname=u"Doe",
    ...     sex=u"f",
    ...     birthdate="1980-01-01",
    ... )
    >>> patient_fhir_uid = fapi.generate_UUID().hex
    >>> fapi.set_fhir_uids(patient, Patient=patient_fhir_uid)
    >>> transaction.commit()
    >>> with_patient = new_linked_analysis(mrn="MRN-0001")

Without ``_include``, the bundle contains only ``ServiceRequest`` entries:

    >>> url = base_url + "&_count=1"
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> resource_types = set(
    ...     e["resource"]["resourceType"] for e in bundle["entry"])
    >>> resource_types == {"ServiceRequest"}
    True

With ``_include=Patient:subject`` the bundle also contains the Patient
referenced by that ServiceRequest's ``subject``:

    >>> url = base_url + "&_count=1&_include=Patient:subject"
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> resource_types = set(
    ...     e["resource"]["resourceType"] for e in bundle["entry"])
    >>> resource_types == {"ServiceRequest", "Patient"}
    True

The included Patient entry carries ``search.mode = "include"`` and a
``fullUrl`` prefixed with ``Patient/``:

    >>> include_entries = [
    ...     e for e in bundle["entry"] if e["search"]["mode"] == "include"]
    >>> len(include_entries)
    1
    >>> include_entries[0]["resource"]["resourceType"]
    u'Patient'
    >>> patient_url = u"Patient/%s" % str(fapi.get_uuid(patient_fhir_uid))
    >>> include_entries[0]["fullUrl"] == patient_url
    True

The subject reference uses the Patient's FHIR identity, even when it differs
from the SENAITE object UID, and therefore resolves to the included entry:

    >>> subject_ref = next(e for e in bundle["entry"]
    ...                    if e["search"]["mode"] == "match")["resource"]["subject"]["reference"]
    >>> subject_ref == include_entries[0]["fullUrl"]
    True

``Bundle.total`` still only counts ServiceRequest matches, unaffected by
the include:

    >>> bundle["total"]
    4

Only Patients referenced from ServiceRequests on the current page are
included: a page that excludes the Patient-linked ServiceRequest returns
no Patient entries, even though that Patient exists:

    >>> url = base_url + "&_count=3&_offset=1&_include=Patient:subject"
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> entries = bundle["entry"]
    >>> any(e["resource"]["resourceType"] == "Patient" for e in entries)
    False


_include=Specimen:specimen adds Specimen entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``Specimen:specimen`` resolves the Specimen referenced by each ServiceRequest
on the current page. Repeated ``_include`` parameters are both respected, so
the Patient and Specimen can be requested together:

    >>> url = (base_url + "&_count=1&_include=Patient:subject"
    ...        "&_include=Specimen:specimen")
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> resource_types = set(
    ...     e["resource"]["resourceType"] for e in bundle["entry"])
    >>> resource_types == {"ServiceRequest", "Patient", "Specimen"}
    True

The included Specimen is appended after the page's match entries, carries
``search.mode = \"include\"``, and does not change ``Bundle.total``:

    >>> entries = bundle["entry"]
    >>> [e["search"]["mode"] for e in entries].count("match")
    1

    >>> sorted(e["resource"]["resourceType"] for e in entries
    ...        if e["search"]["mode"] == "include")
    [u'Patient', u'Specimen']

    >>> specimen_entry = next(
    ...     e for e in entries if e["resource"]["resourceType"] == "Specimen")
    >>> specimen_ref = entries[0]["resource"]["specimen"][0]["reference"]
    >>> specimen_entry["fullUrl"] == specimen_ref
    True

    >>> bundle["total"]
    4

Requesting an unsupported ``_include`` value returns a ``400``
OperationOutcome:

    >>> browser.raiseHttpErrors = False
    >>> url = base_url + "&_include=Practitioner:performer"
    >>> browser.open(url)
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["code"]
    u'not-supported'
    >>> outcome["issue"][0]["expression"]
    [u'_include']

    >>> browser.raiseHttpErrors = True
