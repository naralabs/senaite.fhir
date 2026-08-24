FHIR secondary resources
------------------------

Most FHIR resources have a counterpart content type in SENAITE: a
``ServiceRequest`` is an AnalysisRequest, an ``Observation`` is an Analysis, a
``Patient`` is a Patient. They are always rebuilt from that live content by
their ``IContentToFHIR`` adapter, so what the API returns keeps reflecting the
current state of the object rather than the payload that created it.

A ``Specimen`` has no such counterpart -- ``SampleType`` only carries its type
-- so there is nothing to rebuild it from. Resources like this one are linked
as **secondary**: ``link_fhir_resource(obj, resource, secondary=True)``
snapshots them in the type-keyed ``resources`` slot of the object's FHIR
annotation storage, and ``get_fhir_resource`` serves them back from there.

Because the two kinds are read back differently, a resource that *does* have a
counterpart must never end up in the ``resources`` slot: a stale snapshot
would shadow the live one.

This test covers:

- ``get_secondary_resources``, the hand-over that converters use to declare
  secondary resources for the object being created or updated;
- the ``Specimen`` of a posted ``ServiceRequest`` being linked as secondary to
  the created sample and served back verbatim;
- the sample's own ``ServiceRequest`` *not* being snapshotted as secondary;
- secondary resources being re-linked when the resource is updated.

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
``Organization`` by ``ClientID``, the SampleType matches the ``Specimen`` by
its SNOMED display, and each AnalysisService matches one ``orderDetail`` entry
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

Load the bundle and keep its ``Specimen`` and ``ServiceRequest`` at hand:

    >>> raw = resource_string("senaite.fhir.tests", "data/Bundle.06.json")
    >>> bundle = json.loads(raw)
    >>> bundle["type"]
    u'transaction'

    >>> def entry_of(resource_type):
    ...     return [e["resource"] for e in bundle["entry"]
    ...             if e["resource"]["resourceType"] == resource_type][0]

    >>> posted_specimen = entry_of("Specimen")
    >>> posted_sr = entry_of("ServiceRequest")


get_secondary_resources
~~~~~~~~~~~~~~~~~~~~~~~

Converters declare their secondary resources under the
``SECONDARY_RESOURCES_KEY`` key of the content dict, and
``get_secondary_resources`` reads them back:

    >>> from senaite.fhir.config import SECONDARY_RESOURCES_KEY
    >>> SECONDARY_RESOURCES_KEY
    '_fhir_secondary_resources'

    >>> specimen = fapi.to_fhir_resource(posted_specimen)
    >>> data = {SECONDARY_RESOURCES_KEY: [specimen],
    ...         "ClientSampleID": "CSID-01"}
    >>> fapi.get_secondary_resources(data) == [specimen]
    True

The content dict is left untouched. The key is no content field name -- those
are public, and always come with an accessor and a mutator -- so it is simply
ignored when the rest of the dict is applied to the object:

    >>> sorted(data.keys())
    ['ClientSampleID', '_fhir_secondary_resources']

A single resource is accepted as well as a list of them. FHIR resources are
``dict`` subclasses, so a bare resource has to be wrapped rather than
iterated: iterating it would yield its *keys* instead of the resource itself:

    >>> bare = {SECONDARY_RESOURCES_KEY: specimen}
    >>> fapi.get_secondary_resources(bare) == [specimen]
    True

Missing, empty and non-resource values yield an empty list:

    >>> fapi.get_secondary_resources({})
    []
    >>> fapi.get_secondary_resources({SECONDARY_RESOURCES_KEY: None})
    []
    >>> fapi.get_secondary_resources({SECONDARY_RESOURCES_KEY: []})
    []
    >>> fapi.get_secondary_resources({SECONDARY_RESOURCES_KEY: [None, 1]})
    []


The Specimen is linked as a secondary resource
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Post the bundle:

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
    >>> sample.getSampleType() == blood
    True

The Specimen's FHIR id is linked to the sample, alongside the sample's own
``ServiceRequest`` id:

    >>> fapi.get_fhir_id(sample, "Specimen") == posted_specimen["id"]
    True
    >>> fapi.get_fhir_id(sample, "ServiceRequest") == posted_sr["id"]
    True

Only the ``Specimen`` is snapshotted in the ``resources`` slot. The sample's
own ``ServiceRequest`` is not: it has a counterpart content type, so a
snapshot of it would shadow the live one:

    >>> storage = fapi.get_fhir_storage(sample)
    >>> sorted(storage.get("resources").keys())
    [u'Specimen']


Reading back a secondary resource
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``get_fhir_resource`` returns the Specimen exactly as it came in, with the id,
the SNOMED type coding, the collection body site and the notes carried by the
bundle:

    >>> stored = fapi.get_fhir_resource(sample, "Specimen")
    >>> stored.resourceType
    u'Specimen'
    >>> stored.id == posted_specimen["id"]
    True
    >>> stored["type"]["coding"][0]["code"]
    u'119364003'
    >>> stored["collection"]["bodySite"]["concept"]["coding"][0]["display"]
    u'Antecubital fossa'
    >>> "No lipemia observed." in stored["note"][0]["text"]
    True

This is *not* what the ``AnalysisRequestToSpecimen`` adapter would synthesize
from the sample. That one gets its identity from the sample and knows nothing
about the collection details of the incoming Specimen:

    >>> synthesized = fapi.to_fhir_resource(sample, resource_type="Specimen")
    >>> synthesized.id == posted_specimen["id"]
    False
    >>> synthesized.id == str(fapi.get_uuid(api.get_uid(sample)))
    True
    >>> "bodySite" in synthesized.get("collection", {})
    False

The HTTP endpoint serves the stored resource as well, both by the Specimen's
own FHIR id and through the ``Specimen`` listing:

    >>> browser.open("{}/Specimen/{}".format(fhir_url, stored.id))
    >>> served = json.loads(browser.contents)
    >>> served["id"] == posted_specimen["id"]
    True
    >>> served["collection"]["bodySite"]["concept"]["coding"][0]["display"]
    u'Antecubital fossa'

    >>> browser.open("{}/Specimen".format(fhir_url))
    >>> listing = json.loads(browser.contents)
    >>> listing["total"]
    1
    >>> listing["entry"][0]["resource"]["id"] == posted_specimen["id"]
    True


Secondary resources are re-linked on update
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``fapi.update`` links the secondary resources of the incoming resource the
same way ``fapi.create`` does, so the snapshot is refreshed instead of going
stale. Change the collection body site of the posted Specimen:

    >>> body_site = posted_specimen["collection"]["bodySite"]
    >>> body_site["concept"]["coding"][0]["display"] = "Dorsal hand vein"

Rebuild the ``ServiceRequest`` out of the modified bundle. The bundle is
attached to it under ``_bundle``, which is how the endpoint lets a resource
resolve its siblings:

    >>> bundle_resource = fapi.to_fhir_resource(bundle)
    >>> sr_resource = bundle_resource.first_entry("id", posted_sr["id"])
    >>> sr_resource["_bundle"] = bundle_resource

Update the sample with it:

    >>> sample = fapi.update(sample, sr_resource)
    >>> transaction.commit()

The snapshot carries the new body site, and no second Specimen entry was
added -- the resource type is the key, so the same Specimen gets overwritten:

    >>> updated = fapi.get_fhir_resource(sample, "Specimen")
    >>> updated["collection"]["bodySite"]["concept"]["coding"][0]["display"]
    'Dorsal hand vein'
    >>> sorted(fapi.get_fhir_storage(sample).get("resources").keys())
    [u'Specimen']


The Specimen reference is required
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``ServiceRequest.specimen`` is 1..1 in the SenaiteServiceRequest profile, so a
``ServiceRequest`` that carries no Specimen reference has nothing to hand over.
That is a violation of the profile, not an internal error, and it comes back as
a ``400 OperationOutcome`` pointing at the offending element:

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
