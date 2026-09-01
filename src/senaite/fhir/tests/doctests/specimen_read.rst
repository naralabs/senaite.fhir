FHIR Specimen Read
------------------

Verify that ``GET /senaite/@@FHIR/r5/Specimen/<id>`` returns the FHIR
``Specimen`` resource synthesised on-the-fly by the
``AnalysisRequestToSpecimen`` named adapter -- the only source for a
``Specimen``, since it has no counterpart content type of its own and is
never stored (see ``secondary_resources.rst`` for what a bundle-posted
``Specimen`` does and does not carry over).

Also verifies:

- The SNOMED system code (``http://snomed.info/sct``) appears on the ``type``
  and ``bodySite`` codings.
- ``collection.collectedDateTime`` is populated from the AR's DateSampled.
- Both the 36-char dashed UUID and the 32-char hex UID forms are accepted.
- Requests for unknown UUIDs return a ``404``.
- ARs without a ``SamplePoint`` produce a Specimen with no ``bodySite``.

Running this test from the buildout directory:

    bin/test test_doctests -t specimen_read


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

Create the minimum set of objects to register samples:

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


Create native AnalysisRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a native AR with a SampleType, SamplePoint and DateSampled.  The
FHIR layer synthesises a Specimen from it on-the-fly via the
``AnalysisRequestToSpecimen`` named adapter:

    >>> values = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ...     "SamplePoint": samplepoint.UID(),
    ...     "ClientSampleID": "EXT-WB-0042",
    ... }
    >>> sample = create_analysisrequest(client, request, values, [Hb.UID()])
    >>> sample
    <AnalysisRequest at /plone/clients/...>
    >>> sample_uid = api.get_uid(sample)
    >>> transaction.commit()

The synthesised Specimen id is the AR's SENAITE UID reformatted as a
dashed UUID:

    >>> specimen_id = str(uuid.UUID(sample_uid))
    >>> specimen_id != sample_uid
    True


GET /Specimen/<id> – 36-char dashed UUID
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Fetching the native specimen by its dashed-UUID id returns the synthesised
Specimen resource:

    >>> browser.open("{}/Specimen/{}".format(fhir_url, specimen_id))
    >>> spec = json.loads(browser.contents)
    >>> spec["resourceType"]
    u'Specimen'
    >>> spec["id"] == specimen_id
    True

The ``type`` coding carries the SNOMED system code and the SampleType title:

    >>> spec["type"]["coding"][0]["system"]
    u'http://snomed.info/sct'
    >>> spec["type"]["coding"][0]["display"]
    u'Whole Blood'

The `identifier` list carries the sample's ClientSampleID under the
`client-sample-id` naming system, as the `secondary` identifier:

    >>> client_identifier = spec["identifier"][0]
    >>> client_identifier["value"]
    u'EXT-WB-0042'
    >>> client_identifier["use"]
    u'secondary'
    >>> client_identifier["system"] == (
    ...     "https://fhir.senaite.org/NamingSystem/client-sample-id")
    True

The ``collection.collectedDateTime`` is present and non-empty:

    >>> "collectedDateTime" in spec.get("collection", {})
    True
    >>> bool(spec["collection"]["collectedDateTime"])
    True

The ``collection.bodySite`` coding uses the same SNOMED system and carries
the SamplePoint title:

    >>> spec["collection"]["bodySite"]["concept"]["coding"][0]["system"]
    u'http://snomed.info/sct'
    >>> spec["collection"]["bodySite"]["concept"]["coding"][0]["display"]
    u'Antecubital Vein'


GET /Specimen/<id> – 32-char hex UID
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The same specimen is also reachable via the AR's raw 32-character hex UID
(the route accepts both length-32 and length-36 forms):

    >>> browser.open("{}/Specimen/{}".format(fhir_url, sample_uid))
    >>> spec2 = json.loads(browser.contents)
    >>> spec2["resourceType"]
    u'Specimen'
    >>> spec2["id"] == specimen_id
    True


GET /Specimen/<id> – 404 for unknown id
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A UUID that does not correspond to any AR or stored Specimen returns 404:

    >>> browser.open("{}/Specimen/{}".format(fhir_url,
    ...              "00000000-0000-0000-0000-000000000001"))
    >>> browser.headers["Status"]
    '404 Not Found'


Native specimen without SamplePoint
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An AR created without a ``SamplePoint`` produces a Specimen whose
``collection`` has no ``bodySite``:

    >>> values_no_sp = {
    ...     "Client": client.UID(),
    ...     "Contact": contact.UID(),
    ...     "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...     "SampleType": sampletype.UID(),
    ... }
    >>> sample_no_sp = create_analysisrequest(
    ...     client, request, values_no_sp, [Hb.UID()])
    >>> sample_no_sp_uid = api.get_uid(sample_no_sp)
    >>> transaction.commit()

    >>> sp_id = str(uuid.UUID(sample_no_sp_uid))
    >>> browser.open("{}/Specimen/{}".format(fhir_url, sp_id))
    >>> sp_no_bodysite = json.loads(browser.contents)
    >>> sp_no_bodysite["resourceType"]
    u'Specimen'
    >>> "bodySite" in sp_no_bodysite.get("collection", {})
    False


    >>> browser.raiseHttpErrors = True
