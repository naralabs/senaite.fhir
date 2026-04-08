Alias: $loinc       = http://loinc.org
Alias: $sct         = http://snomed.info/sct
Alias: $opOutcome   = http://terminology.hl7.org/CodeSystem/operation-outcome
Alias: $issueType   = http://hl7.org/fhir/issue-type

// ================================================================
// Invariant: status must be revoked
// ================================================================
Invariant:  status-revoked
Description: "ServiceRequest.status must be revoked for a cancellation"
Expression:  "status = 'revoked'"
Severity:    #error

// ================================================================
// SenaiteServiceRequestCancellation
// Profiles the JSON Patch request body as a FHIR Parameters resource.
// This is the FHIR-idiomatic representation of:
//   PATCH /ServiceRequest/{id}
//   Content-Type: application/json-patch+json
// ================================================================
Profile:     SenaiteServiceRequestCancellation
Parent:      Parameters
Id:          SenaiteServiceRequestCancellation
Title:       "Senaite ServiceRequest Cancellation"
Description: """Represents the JSON Patch body used to cancel (revoke) a
SenaiteServiceRequest. Sent as a PATCH to /ServiceRequest/{id}.
Contains exactly one operation: replace /status with revoked."""
* ^status = #draft
* parameter 1..1
* parameter.name    = "op" (exactly)
* parameter.value[x] ..0
* parameter.part 1..*
* parameter.part ^slicing.discriminator.type = #value
* parameter.part ^slicing.discriminator.path = "name"
* parameter.part ^slicing.rules             = #closed

* parameter.part contains
    op    1..1 and
    path  1..1 and
    value 1..1

* parameter.part[op].name              = "op" (exactly)
* parameter.part[op].value[x] only string
* parameter.part[op].valueString       = "replace" (exactly)

* parameter.part[path].name            = "path" (exactly)
* parameter.part[path].value[x] only string
* parameter.part[path].valueString     = "/status" (exactly)

* parameter.part[value].name           = "value" (exactly)
* parameter.part[value].value[x] only string
* parameter.part[value].valueString    = "revoked" (exactly)


// ================================================================
// SenaiteServiceRequestRevoked
// Profiles the ServiceRequest returned in the 200 OK response body.
// ================================================================
Profile:     SenaiteServiceRequestRevoked
Parent:      SenaiteServiceRequest
Id:          SenaiteServiceRequestRevoked
Title:       "Senaite ServiceRequest Revoked"
Description: """The ServiceRequest resource returned by the server in the
200 OK response body after a successful cancellation PATCH.
Identical to SenaiteServiceRequest but with status fixed to revoked
and meta.versionId required to confirm the update was applied."""
* ^status = #draft
* obeys status-revoked
* meta.versionId 1..1
* meta.lastUpdated 1..1
* status = #revoked (exactly)


// ================================================================
// SenaiteServiceRequestCancellationError
// Profiles the OperationOutcome returned in the 409 Conflict body.
// ================================================================
Profile:     SenaiteServiceRequestCancellationError
Parent:      OperationOutcome
Id:          SenaiteServiceRequestCancellationError
Title:       "Senaite ServiceRequest Cancellation Error"
Description: """The OperationOutcome returned with a 409 Conflict when a
ServiceRequest cannot be revoked, for example because results have
already been published in SENAITE."""
* ^status = #draft
* issue 1..1
* issue.severity  = #error (exactly)
* issue.code      = #conflict (exactly)
* issue.details   1..1
* issue.details.text 1..1
* issue.expression 1..1


// ================================================================
// Example – PATCH request body
// ================================================================
Instance:   CancelLiverPanelRequest
InstanceOf: SenaiteServiceRequestCancellation
Usage:      #example
* parameter.name            = "op"
* parameter.part[op].name       = "op"
* parameter.part[op].valueString = "replace"
* parameter.part[path].name       = "path"
* parameter.part[path].valueString = "/status"
* parameter.part[value].name       = "value"
* parameter.part[value].valueString = "revoked"


// ================================================================
// Example – 200 OK success response body
// ================================================================
Instance:   CancelLiverPanelSuccess
InstanceOf: SenaiteServiceRequestRevoked
Usage:      #example
* meta.versionId   = "2"
* meta.lastUpdated = "2026-04-08T09:15:00+10:00"
* status = #revoked
* intent = #order
* category[0] = $sct#108252007 "Laboratory procedure"
* category[0].text = "Laboratory procedure"
* code = $loinc#24325-3 "Hepatic function 2000 panel - Serum or Plasma"
* subject    = Reference(Patient/ddaf107d-a44d-4b7b-966b-65d82de495cc)
* encounter  = Reference(Encounter/c2019b9a-72eb-4bf8-ae84-6360a5f13fc7)
* requester  = Reference(Practitioner/ab1ecb26-1942-4855-a32d-ee82c62e5327)
* requester.type = "Practitioner"
* specimen[0] = Reference(Specimen/9b8a478f-fd26-4765-8f09-3b3ea0ec6637)


// ================================================================
// Example – 409 Conflict error response body
// ================================================================
Instance:   CancelLiverPanelConflict
InstanceOf: SenaiteServiceRequestCancellationError
Usage:      #example
* issue[0].severity = #error
* issue[0].code     = #conflict
* issue[0].details.coding[0].system = "http://terminology.hl7.org/CodeSystem/operation-outcome"
* issue[0].details.coding[0].code   = #MSG_LOCAL_FAIL
* issue[0].details.text = "ServiceRequest/2d6bb491-6b87-4558-a07f-2d181831e298 cannot be revoked: results have already been published in SENAITE."
* issue[0].expression[0] = "ServiceRequest.status"
