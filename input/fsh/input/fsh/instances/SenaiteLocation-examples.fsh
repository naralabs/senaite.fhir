// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteLocation-examples.fsh                                    │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Hospital ward ---
Instance: SenaiteLocation-001
InstanceOf: SenaiteLocation
Title: "Location: Ward 4B — City General Hospital"
Description: "Inpatient ward from which a ServiceRequest was submitted."
* identifier.system = "http://senaite.example.org/location-id"
* identifier.value = "LOC-001"
* name = "Ward 4B"
* form.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type"
* form.coding.code = #wa
* form.coding.display = "Ward"

// --- Example 2: Emergency department ---
Instance: SenaiteLocation-002
InstanceOf: SenaiteLocation
Title: "Location: Emergency Department — City General Hospital"
Description: "Emergency department requesting urgent biochemistry results."
* identifier.system = "http://senaite.example.org/location-id"
* identifier.value = "LOC-002"
* name = "Emergency Department"
* form.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type"
* form.coding.code = #wi
* form.coding.display = "Wing"

// --- Example 3: Outpatient clinic ---
Instance: SenaiteLocation-003
InstanceOf: SenaiteLocation
Title: "Location: Outpatient Haematology Clinic"
Description: "Specialist outpatient clinic submitting a panel request."
* identifier.system = "http://senaite.example.org/location-id"
* identifier.value = "LOC-003"
* name = "Haematology Outpatient Clinic"
* form.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type"
* form.coding.code = #ro
* form.coding.display = "Room"
