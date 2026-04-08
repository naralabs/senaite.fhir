
## Phased Approach
Previous experience has taught us to divide the project into two distinct phases as determined by separate workflows. These need to be done in order with each delivered into the live environment before the next begins.

Each phase includes:
- Solution customisation to determine whether the default Resource set is usable or additions/extensions are needed.
- Discussion + Agreement across lab/provider/consumer domains on the terminologies and codesets used. For example it is necessary to agree on encoding for profiles and individual tests.
- Release phased update to QA System that consumer are able to test the integration end-to-end. 
- Feedback window for Naralabs in which a scheduled period for feedback/updates/customisation. 
- Release to production and integration monitoring.

### Phase 1: Request/Results Workflow

As described in the [Lab Request and Results workflow description](lab-request-and-results.html), the request/results are the main part of any lab integration. Requests are PUSHED to SENAITE while the results are fetched directly by the External EHR or via the Middleware layer.

The results include optional raw results including numeric, coded and textual results from each test in the diagnostic report as Observations. The devil here is certainly in the detail, because depending on which panels and tests determines the complexity here. For example, microbiological tests can involve some very complicated reflex testing workflows.

### Phase 2: Instrument Workflow
For a full description of this workflow please see [Instrument Integration Workflow](instrument-integration.html). This requires Phase 1 be implemented first as both systems will need to an identified ServiceRequest with which to attach results.

This phase is still in the draft phase. 

## Requirements Discovery: Questions for Implementers
Each integration is different but there is a standard set of questions which can ensure the integration performs correctly.

### Patient Details

- [ ] How will a patient be identified? Please note that multiple identifiers are possible, ranging from logical - an identifier used by a computer system, to a business - such as health id. See discussion [here](https://build.fhir.org/ig/HL7/fhir-for-fair/FHIRidentifiers.html).
- [ ] Is there the ability to merge/demerge patients in the EHR?
- [ ] Do we align initial states in SENAITE using import or initial fetch? If import, what is the structure? 

### Encodings

- [ ] What encodings will you use for:
  - [ ] Panels or Profiles: (ServiceRequest.code) Preferred LOINC.
  - [ ] Tests or subtests: (ServiceRequest.orderDetail\[\]) Preferred LOINC
  - [ ]  Specimen.type: Preferred (SNOMED or <https://terminology.hl7.org/3.1.0/ValueSet-v2-0487.html>)
  - [ ]  What encoding will be used for Practitioner identifier — provider number, HPI-I, local ID?

### Performance
- [ ] What is the results polling frequency?
- [ ] What is the expected daily request volume?
- [ ] Are there peak periods (e.g. Monday morning surge)?

### Error handling and resilience

- [ ] What happens if the consumer's system is unavailable when results are ready?
- [ ] How will failed transactions be surfaced and resolved operationally?

### Existing System

- [ ] Is there an existing manual system for transferring test requests into SENAITE?

If so:

- [ ] Would it be possible to speak with someone to understand that?
- [ ] Would it be possible to get copies of the forms/documentation used in this workflow?

