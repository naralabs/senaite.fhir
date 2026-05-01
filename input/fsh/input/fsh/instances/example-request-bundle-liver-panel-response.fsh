// ============================================================
// Transaction Response Bundle
//
// 5 entries created: Patient, Organization (Client),
// Practitioner, Specimen, ServiceRequest.
// ============================================================
Instance:   LiverPanelTransactionResponse
InstanceOf: SenaiteBundleResponse
Title: "[Bundle] Liver Panel Transaction Response"
Description: """
  Transaction response for the liver panel order. Reflects the
  5-entry request bundle: Patient, Organization (Client),
  Practitioner, Specimen, and ServiceRequest.
"""
Usage: #example
* type = #transaction-response

// entry[0] – Patient (James Nguyen)
* entry[0].fullUrl               = "Patient/ddaf107d-a44d-4b7b-966b-65d82de495cc"
* entry[0].response.status       = "201 Created"
* entry[0].response.lastModified = "2026-04-08T08:31:00+10:00"

// entry[1] – Organization (Royal Melbourne Hospital — Client)
* entry[1].fullUrl               = "Organization/6c248ba7-a4c4-4606-b4a0-efbff71fb902"
* entry[1].response.status       = "201 Created"
* entry[1].response.lastModified = "2026-04-08T08:31:00+10:00"

// entry[2] – Practitioner (Dr. Catherine Sullivan)
* entry[2].fullUrl               = "Practitioner/ab1ecb26-1942-4855-a32d-ee82c62e5327"
* entry[2].response.status       = "201 Created"
* entry[2].response.lastModified = "2026-04-08T08:31:00+10:00"

// entry[3] – Specimen
* entry[3].fullUrl               = "Specimen/9b8a478f-fd26-4765-8f09-3b3ea0ec6637"
* entry[3].response.status       = "201 Created"
* entry[3].response.lastModified = "2026-04-08T08:31:00+10:00"

// entry[4] – ServiceRequest
* entry[4].fullUrl               = "ServiceRequest/2d6bb491-6b87-4558-a07f-2d181831e298"
* entry[4].response.status       = "201 Created"
* entry[4].response.lastModified = "2026-04-08T08:31:00+10:00"
