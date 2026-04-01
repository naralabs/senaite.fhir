// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteDiagnosticReport.fsh                                     │
// │  Lab results report — structured Observations or PDF            │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteDiagnosticReport
Parent: DiagnosticReport
Id: SenaiteDiagnosticReport
Title: "SENAITE Diagnostic Report"
Description: """The results report for a lab test requested via a SenaiteServiceRequest.
May contain either structured results as referenced SenaiteObservations,
or a base64 encoded PDF in presentedForm, or both."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Based On ---
* basedOn 1..1 MS
* basedOn only Reference(SenaiteServiceRequest)
* basedOn ^short = "The ServiceRequest this report fulfils"
* basedOn.extension 0..0
* basedOn.reference 1..1 MS
* basedOn.identifier 0..0
* basedOn.display 0..0

// --- Status ---
* status 1..1 MS
* status ^short = "registered | partial | preliminary | final | entered-in-error"
* status ^definition = "The status of the diagnostic report. Accepts: registered | partial | preliminary | final | entered-in-error."

// --- Code ---
* code 1..1 MS
* code ^short = "LOINC code describing the report"
* code.extension 0..0
* code.coding 1..1 MS
* code.coding.extension 0..0
* code.coding.system = "http://loinc.org" (exactly)
* code.coding.version 0..0
* code.coding.userSelected 0..0

// --- Subject ---
* subject 1..1 MS
* subject only Reference(SenaitePatient)
* subject ^short = "The patient this report is for"
* subject.extension 0..0
* subject.type = "Patient" (exactly)
* subject.identifier 0..0

// --- Result (structured Observations) ---
* result 0..* MS
* result only Reference(SenaiteObservation)
* result ^short = "Structured Observation results — one per individual test"
* result.extension 0..0
* result.type 0..0
* result.identifier 0..0
* result.reference 1..1 MS

// --- Presented Form (PDF report) ---
* presentedForm 0..1 MS
* presentedForm ^short = "Base64 encoded PDF report"
* presentedForm.extension 0..0
* presentedForm.contentType = #application/pdf (exactly)
* presentedForm.data 1..1 MS
* presentedForm.url 0..0
* presentedForm.size 0..0
* presentedForm.hash 0..0
* presentedForm.title 0..0

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* identifier 0..0
* encounter 0..0
* effective[x] 0..0
* issued 0..0
* performer 0..0
* resultsInterpreter 0..0
* specimen 0..0
* note 0..0
* conclusion 0..0
* conclusionCode 0..0
* category 0..0
* composition 0..0
* supportingInfo 0..0
* study 0..0
