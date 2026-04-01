// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteDiagnosticReport-examples.fsh                            │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: FBC report with structured Observations ---
Instance: SenaiteDiagnosticReport-001
InstanceOf: SenaiteDiagnosticReport
Title: "DiagnosticReport: Full Blood Count — James Nguyen (final)"
Description: "Final FBC report referencing structured Observations from the Sysmex XN-1000."
* basedOn = Reference(SenaiteServiceRequest-002)
* status = #final
* code.coding.system = "http://loinc.org"
* code.coding.code = #58410-2
* code.coding.display = "CBC panel - Blood by Automated count"
* subject = Reference(SenaitePatient-001)
* result[+] = Reference(SenaiteInstrumentObservation-001)
* result[+] = Reference(SenaiteInstrumentObservation-002)

// --- Example 2: LFT report with structured Observations including critical result ---
Instance: SenaiteDiagnosticReport-002
InstanceOf: SenaiteDiagnosticReport
Title: "DiagnosticReport: Liver Function Test — Maria Santos (final, critical)"
Description: "Final LFT report with a critically elevated ALT result."
* basedOn = Reference(SenaiteServiceRequest-003)
* status = #final
* code.coding.system = "http://loinc.org"
* code.coding.code = #24325-3
* code.coding.display = "Hepatic function panel"
* subject = Reference(SenaitePatient-002)
* result[+] = Reference(SenaiteInstrumentObservation-003)

// --- Example 3: Report with PDF only (no structured Observations) ---
Instance: SenaiteDiagnosticReport-003
InstanceOf: SenaiteDiagnosticReport
Title: "DiagnosticReport: Haemoglobin — James Nguyen (PDF only)"
Description: "Diagnostic report containing only a base64 encoded PDF. Note: presentedForm.data must be populated at runtime with the actual base64Binary PDF content — FSH does not support inline base64Binary literals."
* basedOn = Reference(SenaiteServiceRequest-001)
* status = #final
* code.coding.system = "http://loinc.org"
* code.coding.code = #718-7
* code.coding.display = "Hemoglobin [Mass/volume] in Blood"
* subject = Reference(SenaitePatient-001)
* presentedForm.contentType = #application/pdf
// presentedForm.data must be set at runtime — base64Binary cannot be expressed as an inline FSH literal
