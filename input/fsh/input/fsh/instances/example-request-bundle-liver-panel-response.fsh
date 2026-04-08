// ============================================================
// Transaction Response Bundle
// ============================================================
Instance:   LiverPanelTransactionResponse
InstanceOf: SenaiteBundleResponse
Usage:      #example
* type = #transaction-response

// ---------------------------------------------------------------
// entry[0] – Patient (James Nguyen)
// ---------------------------------------------------------------
* entry[0].fullUrl                    = "Patient/ddaf107d-a44d-4b7b-966b-65d82de495cc"
* entry[0].response.status            = "201 Created"
* entry[0].response.lastModified      = "2026-04-08T08:31:00+10:00"

// ---------------------------------------------------------------
// entry[1] – Organization (Royal Melbourne Hospital)
// ---------------------------------------------------------------
* entry[1].fullUrl                    = "Organization/6c248ba7-a4c4-4606-b4a0-efbff71fb902"
* entry[1].response.status            = "201 Created"
* entry[1].response.lastModified      = "2026-04-08T08:31:00+10:00"

// ---------------------------------------------------------------
// entry[2] – Location (Hepatology Ward)
// ---------------------------------------------------------------
* entry[2].fullUrl                    = "Location/41834172-8aeb-4814-8a15-77c24d5022cd"
* entry[2].response.status            = "201 Created"
* entry[2].response.lastModified      = "2026-04-08T08:31:00+10:00"

// ---------------------------------------------------------------
// entry[3] – Practitioner (Dr. Catherine Sullivan)
// ---------------------------------------------------------------
* entry[3].fullUrl                    = "Practitioner/ab1ecb26-1942-4855-a32d-ee82c62e5327"
* entry[3].response.status            = "201 Created"
* entry[3].response.lastModified      = "2026-04-08T08:31:00+10:00"

// ---------------------------------------------------------------
// entry[4] – Encounter
// ---------------------------------------------------------------
* entry[4].fullUrl                    = "Encounter/c2019b9a-72eb-4bf8-ae84-6360a5f13fc7"
* entry[4].response.status            = "201 Created"
* entry[4].response.lastModified      = "2026-04-08T08:31:00+10:00"

// ---------------------------------------------------------------
// entry[5] – Specimen
// ---------------------------------------------------------------
* entry[5].fullUrl                    = "Specimen/9b8a478f-fd26-4765-8f09-3b3ea0ec6637"
* entry[5].response.status            = "201 Created"
* entry[5].response.lastModified      = "2026-04-08T08:31:00+10:00"

// ---------------------------------------------------------------
// entry[6] – ServiceRequest
// ---------------------------------------------------------------
* entry[6].fullUrl                    = "ServiceRequest/2d6bb491-6b87-4558-a07f-2d181831e298"
* entry[6].response.status            = "201 Created"
* entry[6].response.lastModified      = "2026-04-08T08:31:00+10:00"
