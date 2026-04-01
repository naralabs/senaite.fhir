// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteEncounter-examples.fsh                                   │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Inpatient encounter ---
Instance: SenaiteEncounter-001
InstanceOf: SenaiteEncounter
Title: "Encounter: Inpatient — Ward 4B"
Description: "Completed inpatient encounter from Ward 4B triggering a full blood count request."
* status = #completed
* class.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
* class.coding.code = #IMP
* class.coding.display = "inpatient encounter"
* location.location = Reference(SenaiteLocation-001)
* serviceProvider = Reference(SenaiteOrganization-001)

// --- Example 2: Emergency encounter ---
Instance: SenaiteEncounter-002
InstanceOf: SenaiteEncounter
Title: "Encounter: Emergency — ED"
Description: "Completed emergency encounter triggering an urgent biochemistry panel."
* status = #completed
* class.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
* class.coding.code = #EMER
* class.coding.display = "emergency"
* location.location = Reference(SenaiteLocation-002)
* serviceProvider = Reference(SenaiteOrganization-001)

// --- Example 3: Outpatient encounter (no service provider) ---
Instance: SenaiteEncounter-003
InstanceOf: SenaiteEncounter
Title: "Encounter: Outpatient — Haematology Clinic"
Description: "Completed outpatient encounter at the haematology clinic — no service provider registered."
* status = #completed
* class.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
* class.coding.code = #AMB
* class.coding.display = "ambulatory"
* location.location = Reference(SenaiteLocation-003)
