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
    >>> import re
    >>> import uuid
    >>> import transaction
    >>> from DateTime import DateTime
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from plone.registry.interfaces import IRegistry
    >>> from bika.lims import api
    >>> from bika.lims.utils.analysisrequest import create_analysisrequest
    >>> from bika.lims.workflow import doActionFor as do_action_for
    >>> from zope.component import getUtility

Variables:

    >>> portal = self.portal
    >>> request = self.request
    >>> setup = portal.setup
    >>> portal_url = portal.absolute_url()
    >>> fhir_url = "{}/@@FHIR/r5".format(portal_url)
    >>> browser = self.getBrowser()
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])
    >>> portal.bika_setup.setSelfVerificationEnabled(True)
    >>> registry = getUtility(IRegistry)
    >>> registry["plone.portal_timezone"] = "Asia/Kolkata"
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
    >>> profile = api.create(setup.analysisprofiles, "AnalysisProfile",
    ...                      title="Metals Panel", ProfileKey="metals-panel")
    >>> profile.setServices([Cu.UID()])


Create the Sample
~~~~~~~~~~~~~~~~~

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ...     "Profiles": [profile.UID()],
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
    >>> transaction.commit()


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

The response body stays valid FHIR: the request runtime is *not* injected
into the payload as a ``_runtime`` key. Instead it is reported through the
W3C ``Server-Timing`` response header, expressed in milliseconds::

    >>> "_runtime" in resource
    False

    >>> re.match(r"^senaite;dur=[\d.]+$", browser.headers["Server-Timing"]) \
    ...     is not None
    True

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

The ``lastUpdated`` field is serialized as a FHIR ``dateTime`` with
seconds and the configured timezone offset:

    >>> pattern = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$"
    >>> re.match(pattern, resource["meta"]["lastUpdated"]) is not None
    True
    >>> resource["meta"]["lastUpdated"].endswith("+05:30")
    True

The published sample maps to a FHIR ``final`` DiagnosticReport status:

    >>> api.get_review_status(sample)
    'published'
    >>> resource["status"]
    u'final'

The ``code`` field is derived from the sample's AnalysisProfile:

    >>> code = resource["code"]
    >>> code["text"]
    u'Metals Panel'
    >>> code["coding"][0]["code"]
    u'metals-panel'

The ``identifier`` list carries at least one entry whose ``value``
matches the sample's internal ID:

    >>> identifiers = resource["identifier"]
    >>> any(i.get("value") == sample_id for i in identifiers)
    True

Internally created samples do not have a backing FHIR ``ServiceRequest``,
so ``basedOn`` is omitted:

    >>> "basedOn" in resource
    False

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


Default Code: Missing AnalysisProfile
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``DiagnosticReport.code`` has a cardinality of ``1..1``, but a sample can be
registered without any ``AnalysisProfile`` assigned (individual tests ordered
directly, with no panel). This must not prevent conversion: the converter
always yields a valid ``DiagnosticReport`` — never an ``OperationOutcome`` and
never ``None`` — falling back to the generic LOINC code `30954-2 Relevant
diagnostic tests/laboratory data note <https://loinc.org/30954-2>`_ for the
mandatory ``code`` element.

Create a sample without a profile:

    >>> values_no_profile = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample_no_profile = create_analysisrequest(client, request, values_no_profile, [Cu.UID()])

Create a ``ResultsReport`` for it:

    >>> report_no_profile = api.create(
    ...     sample_no_profile, "ResultsReport",
    ...     sample=sample_no_profile.UID(),
    ... )
    >>> report_no_profile.setPdf({
    ...     "data": b"%PDF-1.4 fake diagnostic report",
    ...     "filename": u"HH-report.pdf",
    ...     "contentType": "application/pdf",
    ... })
    >>> report_no_profile_uid = api.get_uid(report_no_profile)
    >>> transaction.commit()

Instantiate the converter and call ``to_fhir_resource`` — it returns a regular
``DiagnosticReport`` resource, not an ``OperationOutcome``:

    >>> from senaite.fhir.converter.diagnosticreport import ResultsReportToResource
    >>> converter = ResultsReportToResource(report_no_profile)
    >>> result = converter.to_fhir_resource()
    >>> result["resourceType"]
    'DiagnosticReport'

The ``code`` falls back to the generic LOINC code ``30954-2``:

    >>> code = result["code"]
    >>> code["text"]
    'Relevant diagnostic tests/laboratory data note'
    >>> code["coding"][0]["code"]
    '30954-2'
    >>> code["coding"][0]["system"]
    'http://loinc.org'

The same holds end-to-end through the FHIR route: fetching the report returns
the ``DiagnosticReport`` directly, with no 404 and no ``OperationOutcome``
payload:

    >>> browser.open("{}/DiagnosticReport/{}".format(fhir_url, report_no_profile_uid))
    >>> resource = json.loads(browser.contents)
    >>> resource["resourceType"]
    u'DiagnosticReport'
    >>> resource["code"]["coding"][0]["code"]
    u'30954-2'


Default Code: Multiple AnalysisProfiles
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``DiagnosticReport.code`` cannot represent more than one profile/panel, so the
same generic LOINC code ``30954-2`` is used as a fallback when the sample has
more than one ``AnalysisProfile`` assigned.

Create a second profile and a sample that carries both:

    >>> profile2 = api.create(setup.analysisprofiles, "AnalysisProfile",
    ...                       title="Extra Panel", ProfileKey="extra-panel")
    >>> profile2.setServices([Cu.UID()])
    >>> values_multi_profile = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ...     "Profiles": [profile.UID(), profile2.UID()],
    ... }
    >>> sample_multi_profile = create_analysisrequest(
    ...     client, request, values_multi_profile, [Cu.UID()])
    >>> len(sample_multi_profile.getProfiles())
    2

Create a ``ResultsReport`` for it and convert:

    >>> report_multi_profile = api.create(
    ...     sample_multi_profile, "ResultsReport",
    ...     sample=sample_multi_profile.UID(),
    ... )
    >>> report_multi_profile.setPdf({
    ...     "data": b"%PDF-1.4 fake diagnostic report",
    ...     "filename": u"HH-report.pdf",
    ...     "contentType": "application/pdf",
    ... })
    >>> converter = ResultsReportToResource(report_multi_profile)
    >>> result = converter.to_fhir_resource()
    >>> result["resourceType"]
    'DiagnosticReport'

The ``code`` again falls back to the generic LOINC code ``30954-2`` rather
than picking one of the two assigned profiles:

    >>> code = result["code"]
    >>> code["text"]
    'Relevant diagnostic tests/laboratory data note'
    >>> code["coding"][0]["code"]
    '30954-2'
