FHIR Observation POST (incoming analyzer result)
-------------------------------------------------

Exercises ``POST /Observation``, the endpoint an analyzer/instrument uses to
report back a result for an Analysis it was handed as a
``SenaiteInstrumentServiceRequest`` (see ``instrument_service_request.rst``).

Unlike every other resource type, an Observation POST is not wrapped back
into a ``Bundle`` transaction-response: on success the route returns the
updated ``Observation`` resource directly, and submits the underlying
Analysis (``ResourceToAnalysisResult`` only applies the result; submitting
is a post-hoc side effect in the route, since it isn't a plain field).

Running this test from the buildout directory:

    bin/test test_doctests -t observation_post


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
    >>> from bika.lims.workflow import doActionFor as do_action_for
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

Create the minimum set of objects needed to register a sample, plus an
Instrument the Analysis will be assigned to:

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
    >>> Na = api.create(portal.bika_setup.bika_analysisservices,
    ...                 "AnalysisService", title="Sodium", Keyword="Na",
    ...                 Category=category.UID(), ProtocolID="2951-2",
    ...                 Unit="mmol/L")
    >>> instrument = api.create(portal.bika_setup.bika_instruments,
    ...                         "Instrument", title="GC-MS 1000")
    >>> other_instrument = api.create(portal.bika_setup.bika_instruments,
    ...                               "Instrument", title="HPLC 2000")
    >>> transaction.commit()

A helper that registers, receives and returns a fresh sample together with
its (only) Analysis, assigning it to ``instrument`` so the FHIR
``SenaiteInstrumentServiceRequest`` identity gets linked:

    >>> def new_analysis():
    ...     values = {
    ...         "Client": client.UID(),
    ...         "Contact": contact.UID(),
    ...         "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...         "SampleType": sampletype.UID(),
    ...     }
    ...     sample = create_analysisrequest(client, request, values, [Na.UID()])
    ...     do_action_for(sample, "receive")
    ...     analysis = sample.getAnalyses(full_objects=True)[0]
    ...     analysis.setInstrument(instrument)
    ...     transaction.commit()
    ...     return analysis

A helper that builds a valid ``Observation`` payload reporting a result for
the given Analysis:

    >>> def observation_for(analysis, value=140, unit="mmol/L",
    ...                     code="2951-2", status="final", device=instrument,
    ...                     note=None):
    ...     based_on_id = fapi.get_fhir_id(analysis, "ServiceRequest")
    ...     payload = {
    ...         "resourceType": "Observation",
    ...         "id": str(fapi.generate_UUID()),
    ...         "status": status,
    ...         "basedOn": [{
    ...             "reference": "ServiceRequest/{}".format(based_on_id),
    ...         }],
    ...         "code": {
    ...             "coding": [{"system": "http://loinc.org", "code": code}],
    ...         },
    ...         "valueQuantity": {
    ...             "value": value,
    ...             "unit": unit,
    ...             "system": "http://unitsofmeasure.org",
    ...             "code": unit,
    ...         },
    ...     }
    ...     if device is not None:
    ...         payload["device"] = {
    ...             "reference": "Device/{}".format(fapi.get_fhir_id(device)),
    ...         }
    ...     if note:
    ...         payload["note"] = [{"text": note}]
    ...     return payload

    >>> def post_observation(payload):
    ...     browser.post("{}/Observation".format(fhir_url), json.dumps(payload),
    ...                  content_type="application/json")
    ...     return json.loads(browser.contents)

    >>> def status_code():
    ...     return int(browser.headers["Status"].split(" ", 1)[0])


Successful result submission
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> analysis = new_analysis()
    >>> api.get_workflow_status_of(analysis)
    'unassigned'

    >>> resource = post_observation(observation_for(
    ...     analysis, note="Result within reference range."))
    >>> status_code()
    200

The response is the updated ``Observation`` resource itself, not a
``Bundle``:

    >>> resource["resourceType"]
    u'Observation'

Its status reflects the Analysis' new workflow state (``to_be_verified``
maps to ``preliminary``):

    >>> resource["status"]
    u'preliminary'

The Analysis now carries the submitted result and has been transitioned:

    >>> portal._p_jar.sync()
    >>> analysis.getResult()
    '140'
    >>> analysis.getRemarks()
    'Result within reference range.'
    >>> api.get_workflow_status_of(analysis)
    'to_be_verified'

The response Observation carries the same value back:

    >>> resource["valueQuantity"]["value"]
    u'140'


Validation: Observation.status must be 'final'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> analysis = new_analysis()
    >>> resource = post_observation(observation_for(analysis, status="preliminary"))
    >>> status_code()
    400
    >>> resource["resourceType"]
    u'OperationOutcome'
    >>> issue = resource["issue"][0]
    >>> issue["severity"]
    u'error'
    >>> issue["expression"]
    [u'Observation.status']

The Analysis was not touched:

    >>> portal._p_jar.sync()
    >>> api.get_workflow_status_of(analysis)
    'unassigned'


Validation: Observation.code must match the Analysis service
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> analysis = new_analysis()
    >>> resource = post_observation(observation_for(analysis, code="9999-9"))
    >>> status_code()
    400
    >>> resource["issue"][0]["expression"]
    [u'Observation.code']


Validation: Observation.device must match the assigned Instrument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> analysis = new_analysis()
    >>> resource = post_observation(observation_for(analysis, device=other_instrument))
    >>> status_code()
    400
    >>> resource["issue"][0]["expression"]
    [u'Observation.device']

An Observation without any device is rejected the same way:

    >>> resource = post_observation(observation_for(analysis, device=None))
    >>> status_code()
    400
    >>> resource["issue"][0]["expression"]
    [u'Observation.device']


Validation: Observation.valueQuantity unit must match the Analysis' unit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> analysis = new_analysis()
    >>> resource = post_observation(observation_for(analysis, unit="mg/dL"))
    >>> status_code()
    400
    >>> resource["issue"][0]["expression"]
    [u'Observation.valueQuantity']


Validation: Observation.basedOn is required to locate the Analysis
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> analysis = new_analysis()
    >>> payload = observation_for(analysis)
    >>> del payload["basedOn"]
    >>> resource = post_observation(payload)
    >>> status_code()
    400
    >>> resource["issue"][0]["code"]
    u'required'
    >>> resource["issue"][0]["expression"]
    [u'Observation.basedOn']

An unresolvable ``basedOn`` reference (unknown ServiceRequest) is rejected
as well:

    >>> payload = observation_for(analysis)
    >>> payload["basedOn"] = [{
    ...     "reference": "ServiceRequest/ffffffff-ffff-5fff-9fff-ffffffffffff",
    ... }]
    >>> resource = post_observation(payload)
    >>> status_code()
    400
    >>> resource["issue"][0]["code"]
    u'not-found'


A submitted Analysis can no longer be updated through this endpoint
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once an Analysis has already gone through ``submit``, re-posting a result
for it is a conflict (409), not a plain validation error (400):

    >>> analysis = new_analysis()
    >>> _ = post_observation(observation_for(analysis))
    >>> status_code()
    200
    >>> portal._p_jar.sync()
    >>> api.get_workflow_status_of(analysis)
    'to_be_verified'

    >>> resource = post_observation(observation_for(analysis, value=150))
    >>> status_code()
    409
    >>> resource["issue"][0]["code"]
    u'conflict'
    >>> resource["issue"][0]["expression"]
    [u'Observation.value[x]']
    >>> resource["issue"][0]["details"]["text"]
    u'Observation or DiagnosticReport is locked because it is state: to_be_verified and the value cannot be updated'

The previously submitted result is left untouched:

    >>> portal._p_jar.sync()
    >>> analysis.getResult()
    '140'


Validation: Observation.id cannot be reused for another Analysis
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An Observation identity remains linked to the Analysis it first updated. It
cannot subsequently be used with another Analysis' ServiceRequest.

This matters beyond the result: `note` is applied to the Analysis-level
`Remarks` field, so an Observation reused across two Analyses would claim two
different remark values under a single identity.

    >>> first_analysis = new_analysis()
    >>> first_resource = post_observation(observation_for(
    ...     first_analysis, note="First run, sample lipemic."))
    >>> status_code()
    200
    >>> portal._p_jar.sync()
    >>> first_analysis.getRemarks()
    'First run, sample lipemic.'

Reusing that Observation id for another Analysis is rejected, notes and all:

    >>> second_analysis = new_analysis()
    >>> payload = observation_for(second_analysis, value=150,
    ...                           note="Second run, different remark.")
    >>> payload["id"] = first_resource["id"]
    >>> resource = post_observation(payload)
    >>> status_code()
    409
    >>> resource["issue"][0]["code"]
    u'conflict'
    >>> resource["issue"][0]["expression"]
    [u'Observation.id']
    >>> resource["issue"][0]["details"]["text"]
    u'Observation.id is already linked to different Analysis'

The second Analysis is left untouched -- it took neither the result nor the
remark:

    >>> portal._p_jar.sync()
    >>> second_analysis.getResult()
    ''
    >>> second_analysis.getRemarks()
    ''

...and the remark of the Analysis that owns the Observation is not overwritten:

    >>> first_analysis.getRemarks()
    'First run, sample lipemic.'
