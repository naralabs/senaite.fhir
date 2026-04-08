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

