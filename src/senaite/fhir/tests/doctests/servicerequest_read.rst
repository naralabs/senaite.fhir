FHIR ServiceRequest Read
------------------------

Verify that ``GET /senaite/@@FHIR/r5/ServiceRequest/<uid>`` returns the
instrument-scoped ``SenaiteInstrumentServiceRequest`` resource synthesised
on-the-fly from a SENAITE Analysis, via the
``AnalysisToInstrumentServiceRequest`` named adapter (name ``ServiceRequest``,
registered for ``bika.lims.interfaces.IAnalysis``).

The resource is only produced once the Analysis has been linked to an
instrument-scoped ServiceRequest identity. That link is created (or
refreshed) automatically by the ``setInstrument`` monkey patch
(``senaite.fhir.monkeys.content.analysis``) the moment an Instrument is
assigned to the Analysis -- it mints its own FHIR uid (distinct from the
Analysis' own SENAITE uid) and stamps ``authoredOn``. Until an Instrument
has ever been assigned, ``GET /ServiceRequest/<analysis_uid>`` returns
``404``.

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


Create a native AnalysisRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample = create_analysisrequest(client, request, values, [Hb.UID()])
    >>> analysis = sample.getAnalyses(full_objects=True)[0]
    >>> analysis.setRemarks(u"Sample slightly haemolysed")
    >>> analysis_uid = api.get_uid(analysis)
    >>> transaction.commit()


GET /ServiceRequest/<uid> - 404 before an Instrument is ever assigned
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No ``ServiceRequest`` FHIR identity has been linked yet, so the endpoint
reports ``404`` for the Analysis' own SENAITE uid:

    >>> browser.open("{}/ServiceRequest/{}".format(fhir_url, analysis_uid))
    >>> browser.headers["Status"]
    '404 Not Found'
    >>> fapi.get_fhir_uid(analysis, "ServiceRequest") is None
    True


Assign the Instrument
~~~~~~~~~~~~~~~~~~~~~~

Assigning an Instrument goes through the ``setInstrument`` monkey patch,
which links a ``SenaiteInstrumentServiceRequest`` identity (its own FHIR
uid, distinct from the Analysis' SENAITE uid) and stamps ``authoredOn``:

    >>> analysis.setInstrument(instrument)
    >>> transaction.commit()

    >>> fhir_uid = fapi.get_fhir_uid(analysis, "ServiceRequest")
    >>> fhir_uid is not None
    True
    >>> fhir_uid != analysis_uid
    True
    >>> fhir_id = fapi.get_fhir_id(analysis, "ServiceRequest")


GET /ServiceRequest/<uid> - synthesised SenaiteInstrumentServiceRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The linked ServiceRequest is reachable both by the Analysis' own SENAITE
uid and by its own FHIR id:

    >>> browser.open("{}/ServiceRequest/{}".format(fhir_url, analysis_uid))
    >>> resource = json.loads(browser.contents)
    >>> resource["resourceType"]
    u'ServiceRequest'
    >>> resource["id"] == fhir_id
    True

    >>> browser.open("{}/ServiceRequest/{}".format(fhir_url, fhir_id))
    >>> json.loads(browser.contents)["id"] == fhir_id
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

``authoredOn`` was stamped when the Instrument was assigned:

    >>> bool(resource["authoredOn"])
    True

``performer`` references the assigned Instrument as a FHIR Device:

    >>> import uuid
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


Re-assigning the Instrument refreshes authoredOn, keeping the same identity
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Assigning an Instrument again does not mint a new ServiceRequest identity;
it refreshes the existing one in place:

    >>> analysis.setInstrument(instrument)
    >>> transaction.commit()
    >>> fapi.get_fhir_id(analysis, "ServiceRequest") == fhir_id
    True


GET /ServiceRequest/<uid> - 404 for an unknown uid
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open("{}/ServiceRequest/{}".format(
    ...     fhir_url, "00000000000000000000000000000000"))
    >>> browser.headers["Status"]
    '404 Not Found'

    >>> browser.raiseHttpErrors = True
