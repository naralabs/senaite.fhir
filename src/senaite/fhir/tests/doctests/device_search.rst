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


Create two Instruments
~~~~~~~~~~~~~~~~~~~~~~

Create the first instrument:

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
    >>> "meta" in bundle and "profile" in bundle["meta"]
    False

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


_lastUpdated – far-past threshold includes the instruments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A threshold far in the past returns at least the instruments created above:

    >>> url = "{}/Device?_lastUpdated=gt2000-01-01T00:00:00Z".format(fhir_url)
    >>> browser.open(url)
    >>> filtered = json.loads(browser.contents)
    >>> filtered["resourceType"]
    u'Bundle'
    >>> filtered["total"] >= 2
    True
    >>> filtered_ids = [e["resource"]["id"] for e in filtered.get("entry", [])]
    >>> fhir_id_a in filtered_ids
    True
    >>> fhir_id_b in filtered_ids
    True

_lastUpdated - far-future threshold returns an empty bundle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A threshold far in the future produces an empty bundle without an empty
``entry`` array:

    >>> url = "{}/Device?_lastUpdated=gt2099-12-31T00:00:00Z".format(fhir_url)
    >>> browser.open(url)
    >>> filtered = json.loads(browser.contents)
    >>> filtered["resourceType"]
    u'Bundle'
    >>> filtered["total"]
    0
    >>> "entry" in filtered
    False

Malformed _lastUpdated returns an OperationOutcome error
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.raiseHttpErrors = False
    >>> browser.open("{}/Device?_lastUpdated=not-a-date".format(fhir_url))
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> error = json.loads(browser.contents)
    >>> error["resourceType"]
    u'OperationOutcome'
    >>> issue = error["issue"][0]
    >>> issue["severity"]
    u'error'
    >>> issue["code"]
    u'invalid'
    >>> "_lastUpdated" in issue["expression"]
    True
    >>> browser.raiseHttpErrors = True
