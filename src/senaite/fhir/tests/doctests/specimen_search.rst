FHIR Specimen Search
--------------------

Verify that ``GET /senaite/@@FHIR/r5/Specimen`` returns a FHIR ``Bundle``
of type ``searchset`` covering specimens synthesised on-the-fly from native
SENAITE AnalysisRequests (the ``AnalysisRequestToSpecimen`` named adapter).

Also verifies:

- ``GET /senaite/@@FHIR/r5/Specimen/<id>`` for individual Specimen reads.
- ``bodySite`` is populated from the AR's SamplePoint.
- The ``_lastUpdated`` query parameter filters by the underlying AR's
  modification date.
- A malformed ``_lastUpdated`` value returns a ``400 OperationOutcome``.

Running this test from the buildout directory:

    bin/test test_doctests -t specimen_search


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

Create the minimum set of objects to register a sample:

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Metro Lab", ClientID="ML")
    >>> contact = api.create(client, "Contact",
    ...                      Firstname="Sam", Lastname="Lee")
    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Whole Blood", Prefix="WB")
    >>> samplepoint = api.create(setup.samplepoints, "SamplePoint",
    ...                          title="Antecubital Vein")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Chief")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Haematology", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="CBC", Department=department)
    >>> Hb = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Haemoglobin", Keyword="Hb",
    ...                 Category=category.UID())


Create a native AnalysisRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a native AnalysisRequest (Sample) with a SampleType and SamplePoint.
The FHIR layer synthesises a Specimen from it on-the-fly:

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ...     "SamplePoint": samplepoint.UID(),
    ... }
    >>> sample = create_analysisrequest(client, request, values, [Hb.UID()])
    >>> sample
    <AnalysisRequest at /plone/clients/...>
    >>> sample_uid = api.get_uid(sample)
    >>> transaction.commit()

The synthesised Specimen id is the AR's SENAITE UID reformatted as a dashed
UUID:

    >>> specimen_id = str(uuid.UUID(sample_uid))
    >>> specimen_id != sample_uid
    True


GET /Specimen returns a searchset Bundle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> browser.open("{}/Specimen".format(fhir_url))
    >>> bundle = json.loads(browser.contents)
    >>> bundle["resourceType"]
    u'Bundle'
    >>> bundle["type"]
    u'searchset'
    >>> bundle["total"]
    1

Every entry wraps a Specimen resource with ``search.mode = "match"``:

    >>> entries = bundle["entry"]
    >>> all(e["search"]["mode"] == "match" for e in entries)
    True
    >>> all(e["resource"]["resourceType"] == "Specimen" for e in entries)
    True

The native sample's synthesised Specimen appears in the listing.  Its
``fullUrl`` uses the dashed-UUID form of the AR UID:

    >>> entries[0]["fullUrl"] == "Specimen/{}".format(specimen_id)
    True

The Specimen ``type`` is derived from the AR's SampleType title:

    >>> entries[0]["resource"]["type"]["coding"][0]["display"]
    u'Whole Blood'

The ``collection.bodySite`` is derived from the AR's SamplePoint:

    >>> entries[0]["resource"]["collection"]["bodySite"]["concept"]["coding"][0]["display"]
    u'Antecubital Vein'


GET /Specimen/<id> – individual Specimen read
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Fetching a native specimen by its dashed-UUID id returns the full Specimen
resource:

    >>> browser.open("{}/Specimen/{}".format(fhir_url, specimen_id))
    >>> spec = json.loads(browser.contents)
    >>> spec["resourceType"]
    u'Specimen'
    >>> spec["id"] == specimen_id
    True
    >>> spec["type"]["coding"][0]["display"]
    u'Whole Blood'
    >>> spec["collection"]["bodySite"]["concept"]["coding"][0]["display"]
    u'Antecubital Vein'


_lastUpdated – far-past threshold includes the specimen
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A threshold far in the past returns at least the specimen created above:

    >>> url = "{}/Specimen?_lastUpdated=gt2000-01-01T00:00:00Z".format(fhir_url)
    >>> browser.open(url)
    >>> past_bundle = json.loads(browser.contents)
    >>> past_bundle["total"] >= 1
    True
    >>> any(e["fullUrl"] == "Specimen/{}".format(specimen_id)
    ...     for e in past_bundle.get("entry", []))
    True


_lastUpdated – far-future threshold returns an empty bundle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A threshold far in the future produces an empty bundle:

    >>> url = "{}/Specimen?_lastUpdated=gt2099-12-31T00:00:00Z".format(fhir_url)
    >>> browser.open(url)
    >>> future_bundle = json.loads(browser.contents)
    >>> future_bundle["total"]
    0
    >>> "entry" in future_bundle
    False

The ``gt`` prefix is optional – a bare ISO-8601 instant is also accepted:

    >>> url = "{}/Specimen?_lastUpdated=2000-01-01T00:00:00Z".format(fhir_url)
    >>> browser.open(url)
    >>> json.loads(browser.contents)["total"] >= 1
    True


_lastUpdated – malformed value returns a 400 OperationOutcome
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> url = "{}/Specimen?_lastUpdated=not-a-date".format(fhir_url)
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
