FHIR Task Read
---------------

Verify that ``GET /senaite/@@FHIR/r5/Task/<uid>`` returns the FHIR ``Task``
resource synthesised on-the-fly from an eligible SENAITE Worksheet, via the
``WorksheetToTask`` named adapter (name ``Task``, registered for
``senaite.core.interfaces.IWorksheet``).

A Worksheet is only eligible once every one of its Analyses has been
assigned the *same* Instrument -- that is exactly what
``WorksheetToTask.get_task_assignment`` requires. Until then,
``GET /Task/<worksheet_uid>`` returns ``404``.

Running this test from the buildout directory:

    bin/test test_doctests -t task_read


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
    >>> from bika.lims.workflow import doActionFor
    >>> from senaite.fhir import api as fapi
    >>> from zope.globalrequest import setRequest

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

Create the minimum set of objects to register a sample with two Analyses,
plus two Instruments:

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Uptown Labs", ClientID="UL")
    >>> contact = api.create(client, "Contact",
    ...                      Firstname="Nia", Lastname="Okoro")
    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Serum", Prefix="SR")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Head")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Chemistry", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="Metabolic", Department=department)
    >>> Glu = api.create(portal.bika_setup.bika_analysisservices,
    ...                  "AnalysisService", title="Glucose", Keyword="Glu",
    ...                  Category=category.UID())
    >>> Na = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Sodium", Keyword="Na",
    ...                 Category=category.UID())
    >>> instr_type = api.create(setup.instrumenttypes, "InstrumentType",
    ...                         title=u"Chemistry Analyser")
    >>> instrument = api.create(portal.bika_setup.bika_instruments,
    ...                        "Instrument", title=u"Cobas 6000",
    ...                        InstrumentType=instr_type)
    >>> other_instrument = api.create(portal.bika_setup.bika_instruments,
    ...                              "Instrument", title=u"Architect c4000",
    ...                              InstrumentType=instr_type)
    >>> transaction.commit()


Create and receive a native AnalysisRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A Worksheet can only take in Analyses of a received sample:

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample = create_analysisrequest(
    ...     client, request, values, [Glu.UID(), Na.UID()])
    >>> doActionFor(sample, "receive")
    (True, '')
    >>> glucose, sodium = sample.getAnalyses(full_objects=True)
    >>> transaction.commit()


GET /Task/<uid> - 404 for an empty Worksheet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An empty Worksheet has no Analyses at all, so it is never eligible:

    >>> worksheet = api.create(portal.worksheets, "Worksheet")
    >>> worksheet_uid = api.get_uid(worksheet)
    >>> transaction.commit()

    >>> browser.open("{}/Task/{}".format(fhir_url, worksheet_uid))
    >>> browser.headers["Status"]
    '404 Not Found'


GET /Task/<uid> - 404 before an Instrument is assigned
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Adding both Analyses to the Worksheet is not enough on its own -- none of
them carries an Instrument yet. ``addAnalysis`` requires a worksheet
context on the global request, which the ``browser.open`` call above just
cleared, so it is restored first:

    >>> setRequest(request)
    >>> worksheet.addAnalysis(glucose)
    >>> worksheet.addAnalysis(sodium)
    >>> transaction.commit()

    >>> browser.open("{}/Task/{}".format(fhir_url, worksheet_uid))
    >>> browser.headers["Status"]
    '404 Not Found'


GET /Task/<uid> - 404 when Analyses don't share the same Instrument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A Worksheet whose Analyses are split across more than one Instrument is not
a coherent instrument worklist either, so it stays ineligible:

    >>> glucose.setInstrument(instrument)
    >>> sodium.setInstrument(other_instrument)
    >>> transaction.commit()

    >>> browser.open("{}/Task/{}".format(fhir_url, worksheet_uid))
    >>> browser.headers["Status"]
    '404 Not Found'


GET /Task/<uid> - synthesised Task once every Analysis shares one Instrument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Re-assigning Sodium to the same Instrument as Glucose makes the Worksheet
eligible:

    >>> sodium.setInstrument(instrument)
    >>> transaction.commit()

    >>> browser.open("{}/Task/{}".format(fhir_url, worksheet_uid))
    >>> browser.headers["Status"]
    '200 OK'
    >>> resource = json.loads(browser.contents)
    >>> resource["resourceType"]
    u'Task'

The Worksheet gets its own, stable FHIR Task uid (distinct from its own
SENAITE uid), and the resource is reachable through it too:

    >>> fhir_id = fapi.get_fhir_id(worksheet, "Task")
    >>> resource["id"] == fhir_id
    True
    >>> fhir_id == api.get_uid(worksheet)
    False

    >>> browser.open("{}/Task/{}".format(fhir_url, fhir_id))
    >>> json.loads(browser.contents)["id"] == fhir_id
    True

``intent`` is always ``order``:

    >>> resource["intent"]
    u'order'

``status`` is derived from the Worksheet's review_state (a freshly-created
Worksheet maps to ``draft``):

    >>> api.get_review_status(worksheet)
    'open'
    >>> resource["status"]
    u'draft'

``identifier`` carries the Worksheet's id under the ``worksheet-id`` naming
system:

    >>> resource["identifier"][0]["value"] == worksheet.getId()
    True
    >>> resource["identifier"][0]["use"]
    u'usual'

``requestedPerformer`` references the shared Instrument as a FHIR Device:

    >>> import uuid
    >>> resource["requestedPerformer"][0]["reference"] == "Device/{}".format(
    ...     str(uuid.UUID(api.get_uid(instrument))))
    True

``input`` references the instrument-scoped ServiceRequest of each Analysis:

    >>> len(resource["input"])
    2
    >>> sorted(item["valueReference"]["reference"] for item in resource["input"]) == sorted(  # noqa: E501
    ...     "ServiceRequest/{}".format(fapi.get_fhir_id(analysis, "ServiceRequest"))
    ...     for analysis in (glucose, sodium))
    True

``authoredOn`` and ``meta.lastUpdated`` are stamped:

    >>> bool(resource["authoredOn"])
    True
    >>> bool(resource["meta"]["lastUpdated"])
    True

No WorksheetTemplate was used, so the capacity extension reports ``0``:

    >>> resource["extension"][0]["url"]
    u'https://fhir.senaite.org/StructureDefinition/WorksheetCapacity'
    >>> resource["extension"][0]["valuePositiveInt"]
    0


Submitting results transitions the Task's status
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once every Analysis is submitted, the Worksheet moves to
``to_be_verified``, which maps to the FHIR ``on-hold`` status:

    >>> glucose.setResult(95)
    >>> doActionFor(glucose, "submit")
    (True, '')
    >>> sodium.setResult(140)
    >>> doActionFor(sodium, "submit")
    (True, '')
    >>> transaction.commit()

    >>> api.get_review_status(worksheet)
    'to_be_verified'
    >>> browser.open("{}/Task/{}".format(fhir_url, fhir_id))
    >>> json.loads(browser.contents)["status"]
    u'on-hold'

The Task keeps the same identity across the transition:

    >>> fapi.get_fhir_id(worksheet, "Task") == fhir_id
    True


GET /Task/<uid> - 404 for an unknown uid
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open("{}/Task/{}".format(
    ...     fhir_url, "00000000000000000000000000000000"))
    >>> browser.headers["Status"]
    '404 Not Found'

    >>> browser.raiseHttpErrors = True
