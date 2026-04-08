Alias: $loinc       = http://loinc.org
Alias: $sct         = http://snomed.info/sct
Alias: $opOutcome   = http://terminology.hl7.org/CodeSystem/operation-outcome

// ================================================================
// Step 1 – PATCH request body
//
// PATCH /ServiceRequest/2d6bb491-6b87-4558-a07f-2d181831e298
// Content-Type: application/json-patch+json
// ================================================================
Instance:   CancelLiverPanelRequest
InstanceOf: SenaiteServiceRequestCancellation
Title: "[Parameters] Cancel Liver Panel Request"
Description: "Parameters resource for cancelling a liver panel service request using JSON Patch operations."
Usage:      #example
* parameter.name                    = "op"
* parameter.part[op].name           = "op"
* parameter.part[op].valueString    = "replace"
* parameter.part[path].name         = "path"
* parameter.part[path].valueString  = "/status"
* parameter.part[value].name        = "value"
* parameter.part[value].valueString = "revoked"


// ================================================================
// Step 2a – Success: 200 OK
//
// The server returns the updated ServiceRequest with status revoked.
// meta.versionId increments from 1 to 2 confirming the update.
// ================================================================
Instance:   CancelLiverPanelSuccess
InstanceOf: SenaiteServiceRequestRevoked
Usage:      #example
* id                   = "2d6bb491-6b87-4558-a07f-2d181831e298"
* meta.versionId       = "2"
* meta.lastUpdated     = "2026-04-08T09:15:00+10:00"
* status               = #revoked
* intent               = #order
* category[0]          = $sct#108252007 "Laboratory procedure"
* category[0].text     = "Laboratory procedure"
* code                 = $loinc#24325-3 "Hepatic function 2000 panel - Serum or Plasma"
* subject              = Reference(Patient/ddaf107d-a44d-4b7b-966b-65d82de495cc)
* encounter            = Reference(Encounter/c2019b9a-72eb-4bf8-ae84-6360a5f13fc7)
* requester            = Reference(Practitioner/ab1ecb26-1942-4855-a32d-ee82c62e5327)
* requester.type       = "Practitioner"
* specimen[0]          = Reference(Specimen/9b8a478f-fd26-4765-8f09-3b3ea0ec6637)


// ================================================================
// Step 2b – Failure: 409 Conflict
//
// Returned instead of Step 2a when the ServiceRequest cannot be
// revoked because results have already been published in SENAITE.
// Nothing is changed on the server.
// ================================================================
Instance:   CancelLiverPanelConflict
InstanceOf: SenaiteServiceRequestCancellationError
Usage:      #example
* issue[0].severity             = #error
* issue[0].code                 = #conflict
* issue[0].details.coding[0].system = "http://terminology.hl7.org/CodeSystem/operation-outcome"
* issue[0].details.coding[0].code   = #MSG_LOCAL_FAIL
* issue[0].details.text         = "ServiceRequest/2d6bb491-6b87-4558-a07f-2d181831e298 cannot be revoked: results have already been published in SENAITE."
* issue[0].expression[0]        = "ServiceRequest.status"


// ================================================================
// Step 2c – Failure: 404 Not Found
//
// Returned when no ServiceRequest exists with the supplied id.
// ================================================================
Instance:   CancelLiverPanelNotFound
InstanceOf: OperationOutcome
Usage:      #example
* issue[0].severity             = #error
* issue[0].code                 = #not-found
* issue[0].details.coding[0].system = "http://terminology.hl7.org/CodeSystem/operation-outcome"
* issue[0].details.coding[0].code   = #MSG_NO_EXIST
* issue[0].details.text         = "ServiceRequest/2d6bb491-6b87-4558-a07f-2d181831e298 does not exist on this server."
* issue[0].expression[0]        = "ServiceRequest.id"


// ================================================================
// Step 2d – Failure: 400 Bad Request
//
// Returned when the PATCH body is malformed or the value supplied
// for /status is not a valid ServiceRequest status code.
// ================================================================
Instance:   CancelLiverPanelBadRequest
InstanceOf: OperationOutcome
Usage:      #example
* issue[0].severity             = #error
* issue[0].code                 = #invalid
* issue[0].details.coding[0].system = "http://terminology.hl7.org/CodeSystem/operation-outcome"
* issue[0].details.coding[0].code   = #MSG_LOCAL_FAIL
* issue[0].details.text         = "Invalid value 'cancelled' for ServiceRequest.status. Expected one of: draft | active | on-hold | revoked | entered-in-error."
* issue[0].expression[0]        = "ServiceRequest.status"
