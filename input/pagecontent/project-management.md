
Previous experience has taught us to divide the project into two mandatory phases with a third optional phase. These need to be done in order but each phase is delivered into the live environment before the next begins.

Each phase includes:

- Solution design for which Resource properties to use.
- Agreement on terminologies.
- Data mapping from internal schema to FHIR Resource.
- User acceptance testing.
- Release process and monitoring.

Please see *FHIR Implementation* section for more details.

## Phase 1: Patient Synchronization

Before the test specific data has been transferred, it is required that patient demographic details be synchronized across the systems. This can operate independently of the next workflow - which will assume all patients in SENAITE are up-to-date. This is a relatively simple integration but is an excellent starting point to build confidence in FHIR and refine communication processes where the parties are new to one another.

## Phase 2: Request/Results Workflow

As described in the diagram below, the captured workflows are the main part of the integration. Requests are made available to SENAITE to fetch and the results are posted back to the External EHR via the Middleware layer.

## \[Optional\] Phase 3: Raw Results

This involves including numeric, coded and textual results from each test in the diagnostic report as Observations. The devil here is certainly in the detail, because depending on which panels and tests determines the complexity here. For example, microbiological tests can involve some very complicated reflex testing workflows.

# Questions for Implementers

Each integration is different but there is a standard set of questions to harmonise data between integrating systems

## Patient Details

- [ ] How will a patient be identified? Please note that multiple identifiers are possible, ranging from logical - an identifier used by a computer system, to a business - such as health id. See discussion [here](https://build.fhir.org/ig/HL7/fhir-for-fair/FHIRidentifiers.html).
- [ ] Is there the ability to merge/demerge patients in the EHR?
- [ ] Do we align initial states in SENAITE using import or initial fetch? If import, what is the structure? 

## Encodings

- [ ] What encodings will you use for:
  - [ ] Panels or Profiles: (ServiceRequest.code) Preferred LOINC.
  - [ ] Tests or subtests: (ServiceRequest.orderDetail\[\]) Preferred LOINC
  - [ ]  Specimen.type: Preferred (SNOMED or <https://terminology.hl7.org/3.1.0/ValueSet-v2-0487.html>)

## Existing System

- [ ] Is there an existing manual system for transferring test requests into SENAITE?

If so:

- [ ] Would it be possible to speak with someone to understand that?
- [ ] Would it be possible to get copies of the forms/documentation used in this workflow?