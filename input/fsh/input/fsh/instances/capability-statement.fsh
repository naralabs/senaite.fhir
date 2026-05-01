Alias: $capabilitystatement-expectation = http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation
Instance:     SenaiteCapabilityStatement
InstanceOf:   CapabilityStatement
Title:        "SENAITE FHIR API Capability Statement"
Description:  "Describes the FHIR R5 capabilities of the SENAITE FHIR API when operating as the server (API provider). Covers the lab request and results workflow and the instrument integration workflow."
Usage:        #definition

* name         = "SenaiteCapabilityStatement"
* title        = "SENAITE FHIR API Capability Statement"
* status       = #draft
* experimental = true
* date         = "2026-04-13"
* publisher    = "Naralabs"
* contact[0].name = "Naralabs"
* contact[0].telecom[0].system = #email
* contact[0].telecom[0].value  = "info@naralabs.com"
* description  = "FHIR R5 capability statement for the SENAITE LIMS FHIR API. SENAITE acts as the API server. External consumers and instrument middleware interact with this API to submit lab requests, cancel requests, push instrument results, and retrieve diagnostic reports."
* kind         = #instance
* fhirVersion  = #5.0.0
* format[0]    = #json
* format[1]    = #xml

// ============================================================
// REST capabilities
// ============================================================
* rest[0].mode          = #server
* rest[0].documentation = "SENAITE exposes a FHIR R5 RESTful API supporting the Lab Request and Results workflow and the Instrument Integration workflow."

// ---------------------------------------------------------------
// Bundle
// ---------------------------------------------------------------
* rest[0].resource[0].type = #Bundle
* rest[0].resource[0].documentation = "POST a SenaiteRequestBundle (transaction) to submit a lab request. Returns a SenaiteBundleResponse on success or an OperationOutcome on failure."
* rest[0].resource[0].profile = "http://hl7.org/fhir/StructureDefinition/Bundle"
* rest[0].resource[0].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteRequestBundle"
* rest[0].resource[0].supportedProfile[1] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteBundleResponse"
* rest[0].resource[0].interaction[0].code = #create
* rest[0].resource[0].interaction[0].documentation = "POST a SenaiteRequestBundle transaction to submit a lab request."
* rest[0].resource[0].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[0].interaction[0].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// ServiceRequest
// ---------------------------------------------------------------
* rest[0].resource[1].type = #ServiceRequest
* rest[0].resource[1].documentation = "ServiceRequests are created via a SenaiteRequestBundle transaction and cancelled via PATCH (JSON Patch, replace /status to revoked). Returns 200 OK on success, 409 Conflict if results are published, 404 if not found."
* rest[0].resource[1].profile = "http://hl7.org/fhir/StructureDefinition/ServiceRequest"
* rest[0].resource[1].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteServiceRequest"
* rest[0].resource[1].supportedProfile[1] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteServiceRequestRevoked"
* rest[0].resource[1].interaction[0].code = #read
* rest[0].resource[1].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[1].interaction[0].extension[0].valueCode = #SHALL
* rest[0].resource[1].interaction[1].code = #patch
* rest[0].resource[1].interaction[1].documentation = "Cancel a ServiceRequest. PATCH /ServiceRequest/{id} with Content-Type: application/json-patch+json."
* rest[0].resource[1].interaction[1].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[1].interaction[1].extension[0].valueCode = #SHALL
* rest[0].resource[1].searchParam[0].name = "status"
* rest[0].resource[1].searchParam[0].type = #token
* rest[0].resource[1].searchParam[0].documentation = "Filter by status e.g. status=active. Used by instrument middleware to fetch the worklist."
* rest[0].resource[1].searchParam[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[1].searchParam[0].extension[0].valueCode = #SHALL
* rest[0].resource[1].searchParam[1].name = "_lastUpdated"
* rest[0].resource[1].searchParam[1].type = #date
* rest[0].resource[1].searchParam[1].documentation = "Filter by last updated date. Used by instrument middleware to retrieve only new or changed requests since the last poll."
* rest[0].resource[1].searchParam[1].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[1].searchParam[1].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// DiagnosticReport
// ---------------------------------------------------------------
* rest[0].resource[2].type = #DiagnosticReport
* rest[0].resource[2].documentation = "DiagnosticReports are created internally by SENAITE after results are verified. External consumers poll for new reports and fetch the full PDF via direct read."
* rest[0].resource[2].profile = "http://hl7.org/fhir/StructureDefinition/DiagnosticReport"
* rest[0].resource[2].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteDiagnosticReport"
* rest[0].resource[2].interaction[0].code = #read
* rest[0].resource[2].interaction[0].documentation = "Retrieve a specific DiagnosticReport by id, including the full base64-encoded PDF in presentedForm."
* rest[0].resource[2].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[2].interaction[0].extension[0].valueCode = #SHALL
* rest[0].resource[2].interaction[1].code = #search-type
* rest[0].resource[2].interaction[1].documentation = "Poll for new or updated DiagnosticReports using _lastUpdated, _summary, and _include=DiagnosticReport:result."
* rest[0].resource[2].interaction[1].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[2].interaction[1].extension[0].valueCode = #SHALL
* rest[0].resource[2].searchParam[0].name = "_lastUpdated"
* rest[0].resource[2].searchParam[0].type = #date
* rest[0].resource[2].searchParam[0].documentation = "Filter reports updated since a given datetime. Used by the external consumer to poll for new results."
* rest[0].resource[2].searchParam[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[2].searchParam[0].extension[0].valueCode = #SHALL
* rest[0].resource[2].searchParam[1].name = "_summary"
* rest[0].resource[2].searchParam[1].type = #token
* rest[0].resource[2].searchParam[1].documentation = "Use _summary=true for lightweight polling before fetching full reports."
* rest[0].resource[2].searchParam[1].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[2].searchParam[1].extension[0].valueCode = #SHOULD
* rest[0].resource[2].searchInclude[0] = "DiagnosticReport:result"

// ---------------------------------------------------------------
// Observation
// ---------------------------------------------------------------
* rest[0].resource[3].type = #Observation
* rest[0].resource[3].documentation = "POSTed individually by instrument middleware as results arrive from the instrument. Each Observation references the originating ServiceRequest via basedOn and the instrument via device. Also returned via _include in DiagnosticReport searches."
* rest[0].resource[3].profile = "http://hl7.org/fhir/StructureDefinition/Observation"
* rest[0].resource[3].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteObservation"
* rest[0].resource[3].interaction[0].code = #create
* rest[0].resource[3].interaction[0].documentation = "POST a single SenaiteObservation. Used by instrument middleware to push individual analyte results as they arrive from the instrument."
* rest[0].resource[3].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[3].interaction[0].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// Device
// ---------------------------------------------------------------
* rest[0].resource[4].type = #Device
* rest[0].resource[4].documentation = "Device records are created manually in SENAITE by a lab administrator. The instrument middleware performs a one-time GET at startup to confirm registration and retrieve the logical Device id."
* rest[0].resource[4].profile = "http://hl7.org/fhir/StructureDefinition/Device"
* rest[0].resource[4].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteDevice"
* rest[0].resource[4].interaction[0].code = #search-type
* rest[0].resource[4].interaction[0].documentation = "GET /Device?identifier=<asset_number> to confirm device registration."
* rest[0].resource[4].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[4].interaction[0].extension[0].valueCode = #SHALL
* rest[0].resource[4].searchParam[0].name = "identifier"
* rest[0].resource[4].searchParam[0].type = #token
* rest[0].resource[4].searchParam[0].documentation = "Search by asset register identifier. Used by instrument middleware at startup to confirm device registration."
* rest[0].resource[4].searchParam[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[4].searchParam[0].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// Patient
// ---------------------------------------------------------------
* rest[0].resource[5].type = #Patient
* rest[0].resource[5].documentation = "Created as part of a SenaiteRequestBundle transaction. No direct REST interactions outside the Bundle are defined by this IG."
* rest[0].resource[5].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaitePatient"
* rest[0].resource[5].interaction[0].code = #create
* rest[0].resource[5].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[5].interaction[0].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// Practitioner
// ---------------------------------------------------------------
* rest[0].resource[6].type = #Practitioner
* rest[0].resource[6].documentation = "Created as part of a SenaiteRequestBundle transaction. No direct REST interactions outside the Bundle are defined by this IG."
* rest[0].resource[6].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaitePractitioner"
* rest[0].resource[6].interaction[0].code = #create
* rest[0].resource[6].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[6].interaction[0].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// Specimen
// ---------------------------------------------------------------
* rest[0].resource[7].type = #Specimen
* rest[0].resource[7].documentation = "Created as part of a SenaiteRequestBundle transaction. No direct REST interactions outside the Bundle are defined by this IG."
* rest[0].resource[7].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteSpecimen"
* rest[0].resource[7].interaction[0].code = #create
* rest[0].resource[7].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[7].interaction[0].extension[0].valueCode = #SHALL

// ---------------------------------------------------------------
// Organization — REQUIRED in Bundle
// Every SenaiteRequestBundle must include the submitting Client
// Organisation. Encounter and Location have been removed; the
// Client is now referenced directly from the ServiceRequest via
// the SenaiteClient extension.
// ---------------------------------------------------------------
* rest[0].resource[8].type = #Organization
* rest[0].resource[8].documentation = "Required as part of every SenaiteRequestBundle transaction. Represents the Client Organisation submitting the lab request. Referenced from the ServiceRequest via the SenaiteClient extension. No direct REST interactions outside the Bundle are defined by this IG."
* rest[0].resource[8].supportedProfile[0] = "https://senaite-fhir.naralabs.com/en/StructureDefinition/SenaiteOrganization"
* rest[0].resource[8].interaction[0].code = #create
* rest[0].resource[8].interaction[0].extension[0].url = $capabilitystatement-expectation
* rest[0].resource[8].interaction[0].extension[0].valueCode = #SHALL
