FHIR ServiceRequest Read
------------------------

Verify that ``GET /senaite/@@FHIR/r5/ServiceRequest/<uid>`` returns the
instrument-scoped ``SenaiteInstrumentServiceRequest`` resource synthesised
on-the-fly from a SENAITE Analysis, via the
``AnalysisToInstrumentServiceRequest`` named adapter (name ``ServiceRequest``,
registered for ``bika.lims.interfaces.IAnalysis``).

The resource is only produced once the Analysis has been linked to an
instrument-scoped ServiceRequest identity (tracked, in production, by the
``setInstrument`` monkey patch calling ``fapi.set_fhir_uids``). Until that
link exists, ``GET /ServiceRequest/<analysis_uid>`` returns ``404``.

Running this test from the buildout directory:

    bin/test test_doctests -t servicerequest_read


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

Create the minimum set of objects to register a sample and assign an
Instrument to one of its Analyses:

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


Create a native AnalysisRequest and assign the Instrument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample = create_analysisrequest(client, request, values, [Hb.UID()])
    >>> analysis = sample.getAnalyses(full_objects=True)[0]
    >>> analysis.setInstrument(instrument)
    >>> analysis.setRemarks(u"Sample slightly haemolysed")
    >>> analysis_uid = api.get_uid(analysis)
    >>> transaction.commit()


GET /ServiceRequest/<uid> – 404 before the Instrument link is recorded
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Assigning the Instrument alone does not create the FHIR identity link
(that is the responsibility of the ``setInstrument`` monkey patch, which
records it via ``fapi.set_fhir_uids``). Without that link the Analysis was
"never linked" and the endpoint reports ``404``:

    >>> browser.open("{}/ServiceRequest/{}".format(fhir_url, analysis_uid))
    >>> browser.headers["Status"]
    '404 Not Found'


Record the Instrument link
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Simulate what the ``setInstrument`` monkey patch does: link the Analysis to
its own UID as the ``ServiceRequest`` FHIR identity, and record the moment it
was authored:

    >>> fapi.set_fhir_uids(analysis, ServiceRequest=analysis_uid)
    >>> storage = fapi.get_fhir_storage(analysis)
    >>> authored_on = to_fhir_datetime(DateTime())
    >>> storage["data"] = {"authoredOn": authored_on}
    >>> transaction.commit()


GET /ServiceRequest/<uid> – synthesised SenaiteInstrumentServiceRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open("{}/ServiceRequest/{}".format(fhir_url, analysis_uid))
    >>> resource = json.loads(browser.contents)
    >>> resource["resourceType"]
    u'ServiceRequest'

The ``id`` is the dashed-UUID form of the linked FHIR UID (here, the
Analysis' own UID):

    >>> import uuid
    >>> resource["id"] == str(uuid.UUID(analysis_uid))
    True

``intent`` is always ``filler-order`` for this instrument-scoped flavour:

    >>> resource["intent"]
    u'filler-order'

``status`` is derived from the Analysis' review_state (a freshly-registered
Analysis maps to ``active``):

    >>> api.get_review_status(analysis)
    'registered'
    >>> resource["status"]
    u'active'

``category`` carries the fixed "Laboratory procedure" SNOMED coding:

    >>> resource["category"][0]["coding"][0]["system"]
    u'http://snomed.info/sct'
    >>> resource["category"][0]["coding"][0]["code"]
    u'108252007'

``code`` carries the AnalysisService's LOINC coding and the Analysis title
as text:

    >>> resource["code"]["concept"]["coding"][0]["system"]
    u'http://loinc.org'
    >>> resource["code"]["concept"]["coding"][0]["code"] == Hb.getProtocolID()
    True
    >>> resource["code"]["concept"]["text"] == api.get_title(analysis)
    True

``authoredOn`` reflects the moment the Instrument link was recorded:

    >>> resource["authoredOn"] == authored_on
    True

``performer`` references the assigned Instrument as a FHIR Device:

    >>> resource["performer"][0]["reference"] == "Device/{}".format(
    ...     str(uuid.UUID(api.get_uid(instrument))))
    True

``specimen`` references the owning sample:

    >>> resource["specimen"][0]["reference"] == "Specimen/{}".format(
    ...     str(uuid.UUID(api.get_uid(sample))))
    True

``identifier`` carries the sample's id under the ``servicerequest-id``
naming system:

    >>> resource["identifier"][0]["value"] == sample.getId()
    True
    >>> resource["identifier"][0]["use"]
    u'usual'

``note`` carries the Analysis' remarks:

    >>> resource["note"]
    [{u'text': u'Sample slightly haemolysed'}]

Since the sample was registered natively (not through a FHIR bundle POST)
and has no assigned Patient, ``basedOn`` and ``subject`` are both omitted:

    >>> "basedOn" in resource
    False
    >>> "subject" in resource
    False


GET /ServiceRequest/<uid> – 404 for an unknown uid
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open("{}/ServiceRequest/{}".format(
    ...     fhir_url, "00000000000000000000000000000000"))
    >>> browser.headers["Status"]
    '404 Not Found'

    >>> browser.raiseHttpErrors = True
