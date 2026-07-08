FHIR Device Search
------------------

Verify that the FHIR API route ``/senaite/@@FHIR/r5/Device`` returns a
FHIR searchset Bundle of all SENAITE Instruments, and that the optional
``?_lastUpdated=gt<datetime>`` filter narrows results by modification date.

Running this test from the buildout directory:

    bin/test test_doctests -t device_search


Test Setup
~~~~~~~~~~

Needed imports:

    >>> import json
    >>> import transaction
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from bika.lims import api
    >>> from senaite.core.api import dtime

Variables:

    >>> portal = self.portal
    >>> portal_url = portal.absolute_url()
    >>> fhir_url = "{}/@@FHIR/r5".format(portal_url)
    >>> browser = self.getBrowser()
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])
    >>> setup = api.get_senaite_setup()
    >>> bikasetup = portal.bika_setup
    >>> transaction.commit()


Create supporting setup objects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> instr_type = api.create(
    ...     setup.instrumenttypes,
    ...     "InstrumentType",
    ...     title=u"Spectroscopy",
    ... )
    >>> manufacturer = api.create(
    ...     setup.manufacturers,
    ...     "Manufacturer",
    ...     title=u"PerkinElmer",
    ... )
    >>> supplier = api.create(
    ...     setup.suppliers,
    ...     "Supplier",
    ...     title=u"Lab Supplies Co",
    ... )


Create two Instruments at known times
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create the first instrument and record the timestamp before the second:

    >>> instrument_a = api.create(
    ...     bikasetup.bika_instruments,
    ...     "Instrument",
    ...     title=u"ICP-MS Alpha",
    ...     Manufacturer=manufacturer,
    ...     Supplier=supplier,
    ...     InstrumentType=instr_type,
    ...     Model=u"NexION 300",
    ...     SerialNo=u"SN-A001",
    ... )
    >>> uid_a = api.get_uid(instrument_a)
    >>> transaction.commit()

Record a timestamp between the two instrument creations:

    >>> cutoff = dtime.to_localized_time(dtime.now(), long_format=True)

    >>> instrument_b = api.create(
    ...     bikasetup.bika_instruments,
    ...     "Instrument",
    ...     title=u"ICP-MS Beta",
    ...     Manufacturer=manufacturer,
    ...     Supplier=supplier,
    ...     InstrumentType=instr_type,
    ...     Model=u"NexION 350",
    ...     SerialNo=u"SN-B001",
    ... )
    >>> uid_b = api.get_uid(instrument_b)
    >>> transaction.commit()


Unfiltered list
~~~~~~~~~~~~~~~

Calling ``/senaite/@@FHIR/r5/Device`` returns a FHIR searchset Bundle:

    >>> browser.open("{}/Device".format(fhir_url))
    >>> bundle = json.loads(browser.contents)

The response is a searchset Bundle:

    >>> bundle["resourceType"]
    u'Bundle'
    >>> bundle["type"]
    u'searchset'

Both instruments appear in the bundle:

    >>> ids = [e["resource"]["id"] for e in bundle.get("entry", [])]
    >>> from senaite.fhir import api as fapi
    >>> fhir_id_a = fapi.get_fhir_id(instrument_a)
    >>> fhir_id_b = fapi.get_fhir_id(instrument_b)
    >>> fhir_id_a in ids
    True
    >>> fhir_id_b in ids
    True

The ``total`` field matches the number of entries:

    >>> bundle["total"] == len(bundle.get("entry", []))
    True

Each entry carries a ``search.mode`` of ``match``:

    >>> all(e["search"]["mode"] == "match" for e in bundle.get("entry", []))
    True


Filtered list with _lastUpdated
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Passing ``?_lastUpdated=gt<cutoff>`` returns only Instruments modified
after the cutoff — that is, only ``instrument_b``:

    >>> url = "{}/Device?_lastUpdated=gt{}".format(fhir_url, cutoff)
    >>> browser.open(url)
    >>> filtered = json.loads(browser.contents)
    >>> filtered["resourceType"]
    u'Bundle'

Only ``instrument_b`` is in the filtered result:

    >>> filtered_ids = [e["resource"]["id"] for e in filtered.get("entry", [])]
    >>> fhir_id_b in filtered_ids
    True
    >>> fhir_id_a in filtered_ids
    False


Malformed _lastUpdated returns an OperationOutcome error
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open("{}/Device?_lastUpdated=not-a-date".format(fhir_url))
    >>> error = json.loads(browser.contents)
    >>> error["resourceType"]
    u'OperationOutcome'
    >>> error["issue"][0]["severity"]
    u'error'
    >>> error["issue"][0]["code"]
    u'invalid'
