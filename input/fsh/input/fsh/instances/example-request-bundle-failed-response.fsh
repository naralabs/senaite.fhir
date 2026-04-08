// ============================================================
// OperationOutcome – Unknown LOINC panel code
//
// Returned as the HTTP body with status 422 Unprocessable Entity
// when the ServiceRequest references a LOINC panel code that
// does not exist in SENAITE. The entire transaction is rolled
// back; no resources are created.
// ============================================================
Instance:   UnknownLoincPanelOutcome
InstanceOf: OperationOutcome
Title: "[OperationOutcome] Unknown LOINC Panel Code"
Description: "OperationOutcome returned when a ServiceRequest references an unknown LOINC panel code, causing transaction rollback."
Usage:      #example
* issue[0].severity    = #error
* issue[0].code        = #not-found
* issue[0].details.coding[0].system  = "http://terminology.hl7.org/CodeSystem/operation-outcome"
* issue[0].details.coding[0].code    = #MSG_LOCAL_FAIL
* issue[0].details.text = "LOINC code '24325-3' referenced in ServiceRequest.code is not recognised as a configured panel in SENAITE. Verify the code exists and is active before resubmitting."
* issue[0].expression[0] = "Bundle.entry[6].resource.code"
