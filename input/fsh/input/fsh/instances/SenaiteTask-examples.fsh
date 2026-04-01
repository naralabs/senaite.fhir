// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteTask-examples.fsh                                        │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Task requested — FBC dispatched to Sysmex ---
Instance: SenaiteTask-001
InstanceOf: SenaiteTask
Title: "Task: FBC Dispatched to Sysmex XN-1000 (requested)"
Description: "Task created when the FBC ServiceRequest was fetched by the middleware and dispatched to the Sysmex XN-1000."
* extension[instrument].valueReference = Reference(SenaiteDevice-001)
* identifier.system = "http://senaite.example.org/task-id"
* identifier.value = "TASK-001"
* status = #requested
* intent = #order
* focus = Reference(SenaiteServiceRequest-002)
* for = Reference(SenaitePatient-001)

// --- Example 2: Task in progress — FBC being processed ---
Instance: SenaiteTask-002
InstanceOf: SenaiteTask
Title: "Task: FBC In Progress on Sysmex XN-1000"
Description: "Task updated to in-progress once the Sysmex XN-1000 began processing the specimen."
* extension[instrument].valueReference = Reference(SenaiteDevice-001)
* identifier.system = "http://senaite.example.org/task-id"
* identifier.value = "TASK-002"
* status = #in-progress
* intent = #order
* focus = Reference(SenaiteServiceRequest-002)
* for = Reference(SenaitePatient-001)
* executionPeriod.start = "2024-11-01T10:00:00Z"

// --- Example 3: Task completed — LFT results posted ---
Instance: SenaiteTask-003
InstanceOf: SenaiteTask
Title: "Task: LFT Completed on Roche Cobas c502"
Description: "Task marked completed once all LFT Observations were posted to SENAITE via the Transaction Bundle."
* extension[instrument].valueReference = Reference(SenaiteDevice-002)
* identifier.system = "http://senaite.example.org/task-id"
* identifier.value = "TASK-003"
* status = #completed
* intent = #order
* focus = Reference(SenaiteServiceRequest-003)
* for = Reference(SenaitePatient-002)
* executionPeriod.start = "2024-11-03T08:00:00Z"
* executionPeriod.end = "2024-11-03T08:45:00Z"
* output[+].type.coding.system = "http://loinc.org"
* output[=].type.coding.code = #1742-6
* output[=].valueReference = Reference(SenaiteInstrumentObservation-003)
