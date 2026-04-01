// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteSpecimen-examples.fsh                                    │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Venous blood specimen ---
Instance: SenaiteSpecimen-001
InstanceOf: SenaiteSpecimen
Title: "Specimen: Venous Blood — James Nguyen"
Description: "Venous blood specimen collected from PAT-001 for a full blood count."
* type.coding.system = "http://snomed.info/sct"
* type.coding.code = #122555007
* type.coding.display = "Venous blood specimen"
* subject = Reference(SenaitePatient-001)
* collection.collectedDateTime = "2024-11-01T08:15:00Z"

// --- Example 2: Urine specimen ---
Instance: SenaiteSpecimen-002
InstanceOf: SenaiteSpecimen
Title: "Specimen: Urine — Maria Santos"
Description: "Urine specimen collected from PAT-002 for a urinalysis."
* type.coding.system = "http://snomed.info/sct"
* type.coding.code = #122575003
* type.coding.display = "Urine specimen"
* subject = Reference(SenaitePatient-002)
* collection.collectedDateTime = "2024-11-02T09:00:00Z"

// --- Example 3: Serum specimen ---
Instance: SenaiteSpecimen-003
InstanceOf: SenaiteSpecimen
Title: "Specimen: Serum — James Nguyen"
Description: "Serum specimen from PAT-001 for a liver function test panel."
* type.coding.system = "http://snomed.info/sct"
* type.coding.code = #119364003
* type.coding.display = "Serum specimen"
* subject = Reference(SenaitePatient-001)
* collection.collectedDateTime = "2024-11-03T07:45:00Z"
