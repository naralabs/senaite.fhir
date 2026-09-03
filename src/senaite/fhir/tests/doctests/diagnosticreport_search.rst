FHIR DiagnosticReport Search
-----------------------------

Verify that ``GET /senaite/@@FHIR/r5/DiagnosticReport`` returns a FHIR
``Bundle`` of type ``searchset`` and that the ``_lastUpdated``,
``_summary``, and ``_include`` query parameters behave as specified.

Running this test from the buildout directory:

    bin/test test_doctests -t diagnosticreport_search


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
    >>> from senaite.fhir import api as fapi

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
    ...                     Name="Green Valley", ClientID="GV")
    >>> contact = api.create(client, "Contact",
    ...                      Firstname="Ana", Lastname="Lima")
    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Blood", Prefix="B")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Chief")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Haematology", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="CBC", Department=department)
    >>> Hb = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Haemoglobin", Keyword="Hb",
    ...                 Category=category.UID())
    >>> profile = api.create(setup.analysisprofiles, "AnalysisProfile",
    ...                      title="CBC Panel", ProfileKey="cbc-panel")
    >>> profile.setServices([Hb.UID()])


Create and publish the sample
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ...     "Profiles": [profile.UID()],
    ... }
    >>> sample = create_analysisrequest(client, request, values, [Hb.UID()])
    >>> sample
    <AnalysisRequest at /plone/clients/...>
    >>> sample_uid = api.get_uid(sample)
    >>> sample_id = api.get_id(sample)

    >>> do_action_for(sample, "receive")[0]
    True
    >>> analyses = sample.getAnalyses(full_objects=True)
    >>> for analysis in analyses:
    ...     analysis.setResult(14.5)
    ...     _ = do_action_for(analysis, "submit")
    ...     _ = do_action_for(analysis, "verify")
    >>> do_action_for(sample, "publish")[0]
    True
    >>> api.get_workflow_status_of(sample)
    'published'
    >>> fapi.link_fhir_resource(sample, fapi.to_fhir_resource({
    ...     "resourceType": "ServiceRequest",
    ...     "id": str(uuid.UUID(sample_uid)),
    ...     "code": {
    ...         "concept": {
    ...             "coding": [{
    ...                 "system": "http://loinc.org",
    ...                 "code": "718-7",
    ...                 "display": "Haemoglobin"
    ...             }, {
    ...                 "system": ("https://fhir.senaite.org"
    ...                            "/CodeSystem/analysis-keyword"),
    ...                 "code": "Hb",
    ...                 "display": "Haemoglobin"
    ...             }],
    ...             "text": "CBC",
    ...         },
    ...     },
    ... }))
    >>> transaction.commit()


Create the ResultsReport
~~~~~~~~~~~~~~~~~~~~~~~~

    >>> report = api.create(
    ...     sample, "ResultsReport",
    ...     sample=sample.UID(),
    ... )
    >>> report.setPdf({
    ...     "data": b"%PDF-1.4 fake haemoglobin report",
    ...     "filename": u"GV-report.pdf",
    ...     "contentType": "application/pdf",
    ... })
    >>> report
    <ResultsReport at /plone/clients/...>
    >>> report_uid = api.get_uid(report)
    >>> transaction.commit()


_summary is required
~~~~~~~~~~~~~~~~~~~~~

Calling the endpoint without ``_summary=true`` returns a ``400``
``OperationOutcome``:

    >>> browser.raiseHttpErrors = False
    >>> browser.open("{}/DiagnosticReport".format(fhir_url))
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["resourceType"]
    u'OperationOutcome'
    >>> issue = outcome["issue"][0]
    >>> issue["severity"]
    u'error'
    >>> issue["code"]
    u'required'
    >>> "_summary" in issue["expression"]
    True

Any value other than ``true`` is also rejected:

    >>> browser.open("{}/DiagnosticReport?_summary=false".format(fhir_url))
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> json.loads(browser.contents)["resourceType"]
    u'OperationOutcome'

Re-enable HTTP error raising for the remainder of the tests:

    >>> browser.raiseHttpErrors = True


_summary=true returns a searchset Bundle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A minimal request with ``_summary=true`` returns a ``Bundle`` of type
``searchset``:

    >>> browser.open("{}/DiagnosticReport?_summary=true".format(fhir_url))
    >>> bundle = json.loads(browser.contents)
    >>> bundle["resourceType"]
    u'Bundle'
    >>> bundle["type"]
    u'searchset'

The bundle carries a ``timestamp`` and a ``total`` that reflects the
number of matched ``DiagnosticReport`` resources:

    >>> "timestamp" in bundle
    True
    >>> bundle["total"] >= 1
    True

Every entry has ``search.mode`` set to ``"match"`` and wraps a
``DiagnosticReport`` resource:

    >>> entries = bundle["entry"]
    >>> all(e["search"]["mode"] == "match" for e in entries)
    True
    >>> all(e["resource"]["resourceType"] == "DiagnosticReport"
    ...     for e in entries)
    True

FHIR-linked samples keep a ``basedOn`` reference to the linked
``ServiceRequest``:

    >>> report_entry = [e for e in entries
    ...                 if uuid.UUID(e["resource"]["id"]).hex == report_uid][0]
    >>> report_entry["resource"]["basedOn"][0]["reference"] == \
    ...     u"ServiceRequest/%s" % str(uuid.UUID(sample_uid))
    True

The summary mode strips the base64 PDF payload from ``presentedForm``
while keeping attachment metadata:

    >>> for entry in entries:
    ...     for attachment in entry["resource"].get("presentedForm", []):
    ...         assert "data" not in attachment, \
    ...             "PDF data must not appear in summary responses"
    ...         assert "contentType" in attachment


_lastUpdated – far-past threshold includes the report
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A threshold far in the past returns at least the report created above:

    >>> url = "{}/DiagnosticReport?_summary=true&_lastUpdated=gt2000-01-01T00:00:00Z".format(
    ...     fhir_url)
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> bundle["total"] >= 1
    True
    >>> any(uuid.UUID(e["resource"]["id"]).hex == report_uid
    ...     for e in bundle.get("entry", []))
    True


_lastUpdated – far-future threshold returns an empty bundle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A threshold far in the future produces an empty bundle:

    >>> url = "{}/DiagnosticReport?_summary=true&_lastUpdated=gt2099-12-31T00:00:00Z".format(
    ...     fhir_url)
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> bundle["total"]
    0
    >>> "entry" in bundle
    False

The ``gt`` prefix is optional – a bare ISO-8601 instant is also accepted:

    >>> url = "{}/DiagnosticReport?_summary=true&_lastUpdated=2000-01-01T00:00:00Z".format(
    ...     fhir_url)
    >>> browser.open(url)
    >>> json.loads(browser.contents)["total"] >= 1
    True


_lastUpdated – malformed value returns a 400 OperationOutcome
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.raiseHttpErrors = False
    >>> url = "{}/DiagnosticReport?_summary=true&_lastUpdated=not-a-date".format(
    ...     fhir_url)
    >>> browser.open(url)
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> outcome = json.loads(browser.contents)
    >>> outcome["resourceType"]
    u'OperationOutcome'
    >>> issue = outcome["issue"][0]
    >>> issue["severity"]
    u'error'
    >>> issue["code"]
    u'invalid'
    >>> "_lastUpdated" in issue["expression"]
    True
    >>> browser.raiseHttpErrors = True


_include=Observation:result adds Observation entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Without ``_include``, the bundle contains only ``DiagnosticReport`` entries:

    >>> browser.open("{}/DiagnosticReport?_summary=true".format(fhir_url))
    >>> bundle = json.loads(browser.contents)
    >>> resource_types = set(
    ...     e["resource"]["resourceType"]
    ...     for e in bundle.get("entry", [])
    ... )
    >>> resource_types == {"DiagnosticReport"}
    True

With ``_include=Observation:result`` the bundle also contains
``Observation`` entries:

    >>> url = "{}/DiagnosticReport?_summary=true&_include=Observation:result".format(
    ...     fhir_url)
    >>> browser.open(url)
    >>> bundle = json.loads(browser.contents)
    >>> resource_types = set(
    ...     e["resource"]["resourceType"]
    ...     for e in bundle.get("entry", [])
    ... )
    >>> "DiagnosticReport" in resource_types
    True
    >>> "Observation" in resource_types
    True

``DiagnosticReport`` entries carry ``search.mode = "match"``:

    >>> match_entries = [
    ...     e for e in bundle["entry"]
    ...     if e["search"]["mode"] == "match"
    ... ]
    >>> all(e["resource"]["resourceType"] == "DiagnosticReport"
    ...     for e in match_entries)
    True

``Observation`` entries carry ``search.mode = "include"``:

    >>> include_entries = [
    ...     e for e in bundle["entry"]
    ...     if e["search"]["mode"] == "include"
    ... ]
    >>> all(e["resource"]["resourceType"] == "Observation"
    ...     for e in include_entries)
    True

Each included Observation has a ``fullUrl`` prefixed with ``Observation/``:

    >>> all(e["fullUrl"].startswith("Observation/") for e in include_entries)
    True

Included Observations also point back to the linked ``ServiceRequest``:

    >>> include_entries[0]["resource"]["basedOn"][0]["reference"] == \
    ...     u"ServiceRequest/%s" % str(uuid.UUID(sample_uid))
    True

The number of included Observations matches the reportable analyses on
the sample – one Haemoglobin analysis was published:

    >>> len(include_entries)
    1
    >>> include_entries[0]["resource"]["resourceType"]
    u'Observation'

Included Observations are appended after the ``DiagnosticReport`` matches,
so ``Bundle.total`` keeps counting matches only:

    >>> modes = [e["search"]["mode"] for e in bundle["entry"]]
    >>> modes == sorted(modes, key=lambda mode: mode != "match")
    True

    >>> bundle["total"] == len(match_entries)
    True


Unsupported _include values are rejected
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An ``_include`` value this endpoint does not support returns a ``400``
OperationOutcome:

    >>> browser.raiseHttpErrors = False
    >>> url = "{}/DiagnosticReport?_summary=true".format(fhir_url)
    >>> browser.open(url + "&_include=Practitioner:performer")
    >>> browser.headers["Status"]
    '400 Bad Request'

    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["code"]
    u'not-supported'

    >>> outcome["issue"][0]["expression"]
    [u'_include']

The supported values are declared per endpoint. ``Patient:subject`` is
valid for the ``ServiceRequest`` bundle, but not for this one:

    >>> browser.open(url + "&_include=Patient:subject")
    >>> browser.headers["Status"]
    '400 Bad Request'

    >>> outcome = json.loads(browser.contents)
    >>> outcome["issue"][0]["diagnostics"]
    u'Supported _include values for this endpoint: Observation:result'

An empty ``_include`` is a no-op rather than an error:

    >>> browser.open(url + "&_include=")
    >>> browser.headers["Status"]
    '200 OK'

    >>> bundle = json.loads(browser.contents)
    >>> set(e["search"]["mode"] for e in bundle["entry"])
    set([u'match'])

    >>> browser.raiseHttpErrors = True


Only reportable analyses are included
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The included Observations are the ones referenced by
``DiagnosticReport.result``, which the converter builds out of the
reportable analyses of the sample only. Register a second sample with two
analyses and hide one of them:

    >>> Fe = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Iron", Keyword="Fe",
    ...                 Category=category.UID())
    >>> values2 = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample2 = create_analysisrequest(
    ...     client, request, values2, [Hb.UID(), Fe.UID()])
    >>> _ = do_action_for(sample2, "receive")

    >>> analyses2 = sample2.getAnalyses(full_objects=True)
    >>> hidden = [an for an in analyses2 if an.getKeyword() == "Fe"][0]
    >>> hidden.setHidden(True)

    >>> for analysis in analyses2:
    ...     analysis.setResult(5)
    ...     _ = do_action_for(analysis, "submit")
    ...     _ = do_action_for(analysis, "verify")
    >>> _ = do_action_for(sample2, "publish")

    >>> report2 = api.create(
    ...     sample2, "ResultsReport",
    ...     sample=sample2.UID(),
    ... )
    >>> report2.setPdf({
    ...     "data": b"%PDF-1.4 fake iron report",
    ...     "filename": u"report2.pdf",
    ...     "contentType": "application/pdf",
    ... })
    >>> transaction.commit()

The hidden analysis is not reportable:

    >>> [(an.getKeyword(), fapi.is_reportable(an)) for an in analyses2]
    [('Hb', True), ('Fe', False)]

So it is not included in the bundle, even though its sample is matched:

    >>> url = "{}/DiagnosticReport?_summary=true&_include=Observation:result"
    >>> browser.open(url.format(fhir_url))
    >>> bundle = json.loads(browser.contents)
    >>> included = sorted(e["resource"]["id"] for e in bundle["entry"]
    ...                   if e["search"]["mode"] == "include")

    >>> str(fapi.get_uuid(hidden)) in included
    False

The includes are exactly the reportable analyses of every matched sample:

    >>> expected = set()
    >>> for entry in bundle["entry"]:
    ...     if entry["search"]["mode"] != "match":
    ...         continue
    ...     dr_uid = uuid.UUID(entry["resource"]["id"]).hex
    ...     report = api.get_object(dr_uid)
    ...     for analysis in report.getSample().getAnalyses(full_objects=True):
    ...         if fapi.is_reportable(analysis):
    ...             expected.add(str(fapi.get_uuid(analysis)))

    >>> included == sorted(expected)
    True

    >>> len(included)
    2
