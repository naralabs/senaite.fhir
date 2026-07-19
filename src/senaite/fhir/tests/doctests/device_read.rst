FHIR Device Read
----------------

Verify that a SENAITE Instrument is exposed by the FHIR API route
``/senaite/@@FHIR/r5/Device/<uid>`` and that its JSON representation
maps the Instrument fields to FHIR Device fields correctly.

Running this test from the buildout directory:

    bin/test test_doctests -t device_read


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
    ...     title=u"Atomic Absorption",
    ... )
    >>> manufacturer = api.create(
    ...     setup.manufacturers,
    ...     "Manufacturer",
    ...     title=u"Agilent Technologies",
    ... )
    >>> supplier = api.create(
    ...     setup.suppliers,
    ...     "Supplier",
    ...     title=u"Lab Supplies Co",
    ... )
    >>> location = api.create(
    ...     setup.instrumentlocations,
    ...     "InstrumentLocation",
    ...     title=u"Lab Room 4",
    ... )


Create the Instrument
~~~~~~~~~~~~~~~~~~~~~

    >>> instrument = api.create(
    ...     bikasetup.bika_instruments,
    ...     "Instrument",
    ...     title=u"Atomic Absorption Spectrometer",
    ...     AssetNumber=u"INS-001",
    ...     Manufacturer=manufacturer,
    ...     Supplier=supplier,
    ...     InstrumentType=instr_type,
    ...     Model=u"240FS AA",
    ...     SerialNo=u"SN-20240101",
    ...     InstrumentLocation=location,
    ...     description=u"High-throughput AA spectrometer for metals analysis",
    ... )
    >>> instrument
    <Instrument at /plone/bika_setup/bika_instruments/...>
    >>> uid = api.get_uid(instrument)
    >>> transaction.commit()


Fetch via the FHIR Route
~~~~~~~~~~~~~~~~~~~~~~~~

Calling ``/senaite/@@FHIR/r5/Device/<uid>`` returns the FHIR Device:

    >>> browser.open("{}/Device/{}".format(fhir_url, uid))
    >>> resource = json.loads(browser.contents)

The resource type is ``Device``:

    >>> resource["resourceType"]
    u'Device'

``displayName`` maps to the Instrument title:

    >>> resource["displayName"] == api.get_title(instrument)
    True

``identifier`` carries the asset number with use ``usual``:

    >>> identifiers = resource.get("identifier", [])
    >>> usual = [i for i in identifiers if i.get("use") == "usual"]
    >>> usual[0]["value"] == instrument.getAssetNumber()
    True

``manufacturer`` is the title of the linked Manufacturer object:

    >>> resource["manufacturer"] == api.get_title(instrument.getManufacturer())
    True

``modelNumber`` maps to the Model field:

    >>> resource["modelNumber"] == instrument.getModel()
    True

``serialNumber`` maps to the SerialNo field:

    >>> resource["serialNumber"] == instrument.getSerialNo()
    True

``text`` is a generated narrative with the device title, asset number, and serial number:

    >>> resource["text"]["status"]
    u'generated'
    >>> expected_div = (
    ...     u'<div xmlns="http://www.w3.org/1999/xhtml">'
    ...     u"Device of {} (Asset: {}, Serial number: {})"
    ...     u"</div>"
    ... ).format(
    ...     api.get_title(instrument),
    ...     instrument.getAssetNumber(),
    ...     instrument.getSerialNo(),
    ... )
    >>> resource["text"]["div"] == expected_div
    True

``note[0].text`` is the Instrument description, prefixed with ``Description: ``:

    >>> resource["note"][0]["text"] == u"Description: {}".format(
    ...     instrument.Description())
    True

``note[1].text`` is the location, prefixed with ``Location: ``:

    >>> resource["note"][1]["text"] == u"Location: {}".format(
    ...     api.get_title(instrument.getInstrumentLocation()))
    True

``note[2].text`` is the instrument type, prefixed with ``Instrument Type: ``:

    >>> resource["note"][2]["text"] == u"Instrument Type: {}".format(
    ...     api.get_title(instrument.getInstrumentType()))
    True

``meta.profile`` advertises the SENAITE Device StructureDefinition:

    >>> from senaite.fhir.converter import to_fhir_datetime
    >>> from senaite.fhir.converter import to_fhir_profile_url
    >>> resource["meta"]["profile"] == [to_fhir_profile_url("SenaiteDevice")]
    True

``meta.lastUpdated`` maps to the Instrument modification date:

    >>> resource["meta"]["lastUpdated"] == to_fhir_datetime(
    ...     api.get_modification_date(instrument))
    True

The FHIR resource ``id`` is a stable UUID:

    >>> fhir_id = resource.get("id")
    >>> bool(fhir_id)
    True


Fetch by FHIR ID
~~~~~~~~~~~~~~~~

The resource is also reachable by its FHIR-assigned ``id``:

    >>> browser.open("{}/Device/{}".format(fhir_url, fhir_id))
    >>> resource2 = json.loads(browser.contents)
    >>> resource2["resourceType"]
    u'Device'
    >>> resource2["id"] == fhir_id
    True

Re-fetching via the SENAITE UID returns the same stable ``id``:

    >>> browser.open("{}/Device/{}".format(fhir_url, uid))
    >>> json.loads(browser.contents)["id"] == fhir_id
    True
