FHIR resources that do not have a SENAITE counterpart are never kept exactly as they are
----------------------------------------------------------------------------------------

Most FHIR resources have a counterpart content type in SENAITE: a
`ServiceRequest` is an AnalysisRequest, an `Observation` is an Analysis, a
`Patient` is a Patient. They are always rebuilt from that live content by
their `IContentToFHIR` adapter, so what the API returns keeps reflecting the
current state of the object rather than the payload that created it.

A `Specimen` has no such counterpart -- `SampleType` only carries its type --
so per https://www.hl7.org/fhir/http.html#create a posted `Specimen` is used
only to resolve SENAITE state (its matching `SampleType`) and is never stored
or served back as-is: its own `id`, and any detail the
`AnalysisRequestToSpecimen` adapter has no SENAITE field to rebuild from (a
SNOMED code, free-text notes, ...), do not survive the round trip. `GET`
always synthesizes the `Specimen` from the AnalysisRequest's live data.

This test covers:

- the `Specimen` of a posted `ServiceRequest` resolving the sample's
  `SampleType` but not being linked or stored under its own posted id;
- `get_fhir_resource`/`GET /Specimen` returning the synthesized Specimen
  (derived from the AnalysisRequest's own identity), not the posted one;
- the sample's `ServiceRequest` id also being the AnalysisRequest's own
  SENAITE UID, not the one carried by the bundle, since every resource type's
  posted id is ignored per https://www.hl7.org/fhir/http.html#create;
- `InstrumentServiceRequest.basedOn` still correctly referencing that
  ServiceRequest identity.

Running this test from the buildout directory:

    bin/test test_doctests -t secondary_resources


Test Setup
~~~~~~~~~~

Needed imports:

    >>> import json
    >>> import transaction
    >>> from pkg_resources import resource_string
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from bika.lims import api
    >>> from senaite.fhir import api as fapi

Variables:

    >>> portal = self.portal
    >>> request = self.request
    >>> setup = portal.setup
    >>> fhir_url = "{}/@@FHIR/r5".format(portal.absolute_url())
    >>> browser = self.getBrowser()
    >>> browser.raiseHttpErrors = False
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])

Create the setup objects the bundle resolves against. The Client matches the
`Organization` by `ClientID`, the SampleType matches the `Specimen` by
its SNOMED display, and each AnalysisService matches one `orderDetail` entry
by its LOINC code:

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Royal Melbourne Hospital 2",
    ...                     ClientID="ORG-RMH-MEL")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab", Lastname="Boss")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Cardiology", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="Cardiac", Department=department)
    >>> blood = api.create(setup.sampletypes, "SampleType",
    ...                    title="Blood", Prefix="BLD")
    >>> loinc_codes = ["10839-9", "6598-7", "2157-6", "13969-1", "2532-0",
    ...                "33762-6"]
    >>> for num, code in enumerate(loinc_codes):
    ...     service = api.create(
    ...         portal.bika_setup.bika_analysisservices, "AnalysisService",
    ...         title="CARD %s" % code, Keyword="CARD%s" % num,
    ...         Category=category.UID(), ProtocolID=code)
    >>> transaction.commit()

Load the bundle and keep its `Specimen` and `ServiceRequest` at hand:

    >>> raw = resource_string("senaite.fhir.tests", "data/Bundle.06.json")
    >>> bundle = json.loads(raw)
    >>> bundle["type"]
    u'transaction'

    >>> def entry_of(resource_type):
    ...     return [e["resource"] for e in bundle["entry"]
    ...             if e["resource"]["resourceType"] == resource_type][0]

    >>> posted_specimen = entry_of("Specimen")
    >>> posted_sr = entry_of("ServiceRequest")


Post the bundle
~~~~~~~~~~~~~~~

    >>> browser.post("{}/Bundle".format(fhir_url), json.dumps(bundle),
    ...              content_type="application/json")
    >>> response = json.loads(browser.contents)
    >>> response["type"]
    u'transaction-response'

    >>> portal._p_jar.sync()
    >>> samples = client.objectValues("AnalysisRequest")
    >>> len(samples)
    1
    >>> sample = samples[0]

The posted Specimen resolved the sample's SampleType:

    >>> sample.getSampleType() == blood
    True


The ServiceRequest and Specimen ids both resolve to the sample's own UID
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Per https://www.hl7.org/fhir/http.html#create the posted id is ignored for
every resource type, so `ServiceRequest`'s FHIR id is the AnalysisRequest's
own SENAITE UID, not the one carried by the bundle:

    >>> fapi.get_fhir_id(sample, "ServiceRequest") == posted_sr["id"]
    False
    >>> fapi.get_fhir_id(sample, "ServiceRequest") == str(fapi.get_uuid(api.get_uid(sample)))  # noqa: E501
    True

`Specimen` has no counterpart content type of its own and is never linked at
all, so its posted id is not linked to the sample either:

    >>> fapi.get_fhir_id(sample, "Specimen") is None
    True

The `AnalysisRequestToSpecimen` adapter does not need such a link either: it
derives the Specimen's id straight from the sample's own SENAITE UID:

    >>> synthesized = fapi.to_fhir_resource(sample, resource_type="Specimen")
    >>> synthesized.id == posted_specimen["id"]
    False
    >>> synthesized.id == str(fapi.get_uuid(api.get_uid(sample)))
    True


Reading back the Specimen
~~~~~~~~~~~~~~~~~~~~~~~~~~

`get_fhir_resource` returns the synthesized Specimen, not the one that was
posted: the id differs, and details the adapter has no SENAITE field for
(the SNOMED type code, the collection body site, the notes) are absent:

    >>> served = fapi.get_fhir_resource(sample, "Specimen")
    >>> served.resourceType
    'Specimen'
    >>> served.id == posted_specimen["id"]
    False
    >>> served.id == str(fapi.get_uuid(api.get_uid(sample)))
    True
    >>> served["type"]["coding"][0]["display"]
    'Blood'
    >>> "code" in served["type"]["coding"][0]
    False
    >>> "bodySite" in served.get("collection", {})
    False
    >>> "note" in served
    False

The HTTP endpoint serves the very same synthesized resource, both by the
sample's own FHIR id and through the `Specimen` listing -- the posted id
returns a `404`, since nothing was ever linked or stored under it:

    >>> browser.open("{}/Specimen/{}".format(fhir_url, served.id))
    >>> browser.headers["Status"]
    '200 OK'
    >>> served_via_http = json.loads(browser.contents)
    >>> served_via_http["id"] == served.id
    True

    >>> browser.open("{}/Specimen/{}".format(fhir_url, posted_specimen["id"]))
    >>> browser.headers["Status"]
    '404 Not Found'

    >>> browser.open("{}/Specimen".format(fhir_url))
    >>> listing = json.loads(browser.contents)
    >>> listing["total"]
    1
    >>> listing["entry"][0]["resource"]["id"] == served.id
    True


InstrumentServiceRequest.basedOn points to the sample's ServiceRequest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Assigning an Instrument to one of the sample's Analyses links its own
``SenaiteInstrumentServiceRequest`` identity (see ``servicerequest_read.rst``).
That resource's ``basedOn`` points back to the sample's own ``ServiceRequest``
identity -- its own SENAITE UID, per the section above, not the id originally
carried by the bundle:

    >>> instr_type = api.create(setup.instrumenttypes, "InstrumentType",
    ...                         title=u"Chemistry Analyser")
    >>> instrument = api.create(portal.bika_setup.bika_instruments,
    ...                        "Instrument", title=u"Cobas c311",
    ...                        InstrumentType=instr_type)
    >>> analysis = sample.getAnalyses(full_objects=True)[0]
    >>> analysis.setInstrument(instrument)
    >>> transaction.commit()

    >>> isr_fhir_id = fapi.get_fhir_id(analysis, "ServiceRequest")
    >>> browser.open("{}/ServiceRequest/{}".format(fhir_url, isr_fhir_id))
    >>> isr = json.loads(browser.contents)
    >>> isr["basedOn"][0]["reference"] == "ServiceRequest/{}".format(
    ...     str(fapi.get_uuid(api.get_uid(sample))))
    True
    >>> isr["basedOn"][0]["reference"] == "ServiceRequest/{}".format(
    ...     posted_sr["id"])
    False


The Specimen reference is required
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`ServiceRequest.specimen` is 1..1 in the SenaiteServiceRequest profile, so a
`ServiceRequest` that carries no Specimen reference has nothing to hand over.
That is a violation of the profile, not an internal error, and it comes back as
a `400 OperationOutcome` pointing at the offending element:

    >>> del posted_sr["specimen"]
    >>> browser.post("{}/Bundle".format(fhir_url), json.dumps(bundle),
    ...              content_type="application/json")
    >>> browser.headers["Status"]
    '400 Bad Request'

    >>> outcome = json.loads(browser.contents)
    >>> outcome["resourceType"]
    u'OperationOutcome'
    >>> issue = outcome["issue"][0]
    >>> issue["severity"]
    u'error'
    >>> issue["code"]
    u'required'
    >>> issue["expression"]
    [u'ServiceRequest.specimen']
    >>> issue["details"]["text"]
    u'ServiceRequest.specimen is required'

A repeated reference is rejected the same way, as exceeding the upper bound of
the cardinality:

    >>> posted_sr["specimen"] = [
    ...     {"reference": "Specimen/%s" % posted_specimen["id"]},
    ...     {"reference": "Specimen/%s" % posted_specimen["id"]},
    ... ]
    >>> browser.post("{}/Bundle".format(fhir_url), json.dumps(bundle),
    ...              content_type="application/json")
    >>> browser.headers["Status"]
    '400 Bad Request'
    >>> issue = json.loads(browser.contents)["issue"][0]
    >>> issue["code"]
    u'structure'
    >>> issue["expression"]
    [u'ServiceRequest.specimen']

    >>> browser.raiseHttpErrors = True
