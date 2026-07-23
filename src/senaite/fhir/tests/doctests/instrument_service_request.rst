FHIR Instrument ServiceRequest uid linking
-------------------------------------------

Verify that, whenever an Analysis is assigned an Instrument, it gets a
dedicated FHIR ``SenaiteInstrumentServiceRequest`` uid linked to it (a
``ServiceRequest`` profile, ``intent=filler-order``, device-scoped work
unit). Re-assigning an Instrument keeps the same identity but refreshes
``authoredOn``. Analyses without an Instrument assigned are skipped.

Running this test from the buildout directory:

    bin/test test_doctests -t instrument_service_request


Test Setup
~~~~~~~~~~

Needed imports:

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
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])


Setup objects
~~~~~~~~~~~~~

Create the minimum set of objects needed to register a sample, plus an
Instrument:

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
    >>> instrument = api.create(portal.bika_setup.bika_instruments,
    ...                         "Instrument", title="GC-MS 1000")
    >>> other_instrument = api.create(portal.bika_setup.bika_instruments,
    ...                               "Instrument", title="HPLC 2000")
    >>> transaction.commit()

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


No uid linked before an Instrument is assigned
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> sample = new_sample()
    >>> analysis = sample.getAnalyses(full_objects=True)[0]
    >>> fapi.get_fhir_uid(analysis, "ServiceRequest") is None
    True


Assigning an Instrument links the instrument ServiceRequest uid
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Assigning an Instrument (``setInstrument``) links a uid right away,
regardless of the sample's workflow state:

    >>> api.get_workflow_status_of(sample)
    'sample_due'
    >>> analysis.setInstrument(instrument)
    >>> transaction.commit()

The Analysis now carries a dedicated, stable FHIR
``SenaiteInstrumentServiceRequest`` uid, distinct from its own SENAITE uid
(used for its Observation identity):

    >>> service_request_uid = fapi.get_fhir_uid(analysis, "ServiceRequest")
    >>> service_request_uid is None
    False
    >>> service_request_uid == api.get_uid(analysis)
    False

It is a ``ServiceRequest`` distinguished by ``intent=filler-order``, as
opposed to the panel-level ``SenaiteServiceRequest`` (``intent=order``)
linked to the AnalysisRequest itself, and it carries an ``authoredOn``:

    >>> data = fapi.get_fhir_storage(analysis).get("data")
    >>> data["resourceType"]
    'ServiceRequest'
    >>> data["intent"]
    'filler-order'
    >>> bool(data["authoredOn"])
    True


Re-assigning an Instrument keeps the uid but refreshes authoredOn
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Force a stale ``authoredOn`` to make the refresh observable:

    >>> storage = fapi.get_fhir_storage(analysis)
    >>> data = storage.get("data")
    >>> data["authoredOn"] = "2000-01-01T00:00:00+00:00"
    >>> storage["data"] = data
    >>> transaction.commit()

Re-assigning the Instrument (even a different one) does not mint a new
identity:

    >>> analysis.setInstrument(other_instrument)
    >>> transaction.commit()
    >>> fapi.get_fhir_uid(analysis, "ServiceRequest") == service_request_uid
    True

...but ``authoredOn`` is refreshed:

    >>> fapi.get_fhir_storage(analysis).get("data")["authoredOn"] == "2000-01-01T00:00:00+00:00"
    False


Analyses without an Instrument are skipped
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> other_sample = new_sample()
    >>> other_analysis = other_sample.getAnalyses(full_objects=True)[0]
    >>> fapi.get_fhir_uid(other_analysis, "ServiceRequest") is None
    True

Unassigning the Instrument doesn't mint a new link either, and leaves any
already-linked identity untouched:

    >>> other_analysis.setInstrument(None)
    >>> transaction.commit()
    >>> fapi.get_fhir_uid(other_analysis, "ServiceRequest") is None
    True
