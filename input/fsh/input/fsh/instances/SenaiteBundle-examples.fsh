// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteBundle-examples.fsh                                      │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: FBC Transaction Bundle (2 Observations) ---
Instance: SenaiteBundle-001
InstanceOf: SenaiteBundle
Title: "Bundle: FBC Results — James Nguyen (Sysmex XN-1000)"
Description: "Transaction Bundle posted by the middleware containing FBC Observations for SenaiteServiceRequest-002. Haemoglobin and platelet count included."
* identifier.system = "http://senaite.example.org/bundle-id"
* identifier.value = "BUNDLE-001"
* type = #transaction
* timestamp = "2024-11-01T10:20:00Z"
* entry[+].resource = SenaiteInstrumentObservation-001
* entry[=].request.method = #POST
* entry[=].request.url = "Observation"
* entry[+].resource = SenaiteInstrumentObservation-002
* entry[=].request.method = #POST
* entry[=].request.url = "Observation"

// --- Example 2: LFT Transaction Bundle (single critical Observation) ---
Instance: SenaiteBundle-002
InstanceOf: SenaiteBundle
Title: "Bundle: LFT Results — Maria Santos (Roche Cobas c502)"
Description: "Transaction Bundle posted by the middleware containing a single critically elevated ALT Observation for SenaiteServiceRequest-003."
* identifier.system = "http://senaite.example.org/bundle-id"
* identifier.value = "BUNDLE-002"
* type = #transaction
* timestamp = "2024-11-03T08:45:00Z"
* entry[+].resource = SenaiteInstrumentObservation-003
* entry[=].request.method = #POST
* entry[=].request.url = "Observation"

// --- Example 3: Amended result Bundle (corrected Observation) ---
Instance: SenaiteBundle-003
InstanceOf: SenaiteBundle
Title: "Bundle: Amended FBC Result — James Nguyen (corrected haemoglobin)"
Description: "Transaction Bundle posted by the middleware after an instrument re-run. Contains a corrected haemoglobin Observation replacing the original."
* identifier.system = "http://senaite.example.org/bundle-id"
* identifier.value = "BUNDLE-003"
* type = #transaction
* timestamp = "2024-11-01T11:00:00Z"
* entry[+].resource = SenaiteInstrumentObservation-001
* entry[=].request.method = #POST
* entry[=].request.url = "Observation"
