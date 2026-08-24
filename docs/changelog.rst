Changelog
=========

1.0.0 (Unreleased)
------------------

- #28 Link FHIR resources without a SENAITE counterpart as secondary resources
- #22 Improve Observation result submission validation and remarks handling
- #21 Serialize ServiceRequest Bundle timestamp as FHIR datetime
- #18 Fix bundle POST response status, error handling and None guard
- #19 Add POST /Observation support to submit Analysis results
- #17 Add ServiceRequest endpoints for SenaiteInstrumentServiceRequest resource
- #20 Fix FHIR Device search filtering and empty bundle serialization
- #15 Create FHIR instrument ServiceRequests when an instrument is assigned to an analysis
- #14 Expose SENAITE instruments as FHIR Device resources
- #11 Build Specimen resources from SENAITE Analysis Request data
- #13 Fix dropped marital status on FHIR patient import
- #12 Use additional_phone_numbers for patient phone mapping
- #10 Only emit FHIR basedOn for externally linked service requests
- #9 Validate ServiceRequest orderDetail semantics in Bundle POST
- #8 FHIR id system: decouple FHIR resource ids from SENAITE UIDs
- #5 Build DiagnosticReport resources from SENAITE report data
- #7 Move the _runtime marker from response body to Server-Timing header
- #6 Build Patient FHIR resource from underlying SENAITE patient data
- #3 Implement pollable DiagnosticReport fetch API
- #4 Fix FHIR datetime formatting with timezone offset
- #2 Implement DiagnosticReport PDF report fetch API
- #1 Implement revoke operation for ServiceRequest
- Initial version
