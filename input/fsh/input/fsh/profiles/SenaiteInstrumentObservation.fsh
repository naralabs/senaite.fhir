// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteInstrumentObservation.fsh                                │
// │  Result produced by a lab instrument via middleware             │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteInstrumentObservation
Parent: SenaiteObservation
Id: SenaiteInstrumentObservation
Title: "SENAITE Instrument Observation"
Description: """A quantitative or coded result produced by a laboratory instrument and
forwarded to SENAITE via the middleware as part of a Transaction Bundle.
Extends SenaiteObservation with device attribution and specimen reference.
The observation code must correspond to a LOINC code in the originating
ServiceRequest.orderDetail.parameterFocus."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Device (mandatory for instrument results) ---
* device 1..1 MS
* device only Reference(SenaiteDevice)
* device ^short = "The instrument that produced this result"
* device.reference 1..1 MS
* device.identifier 0..0
* device.display 0..0

// --- Specimen (mandatory for instrument results) ---
* specimen 1..1 MS
* specimen only Reference(SenaiteSpecimen)
* specimen ^short = "The specimen analysed by the instrument"
* specimen.reference 1..1 MS
* specimen.identifier 0..0
* specimen.display 0..0
