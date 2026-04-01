// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteBundle.fsh                                               │
// │  Transaction Bundle for instrument Observation results          │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteBundle
Parent: Bundle
Id: SenaiteBundle
Title: "SENAITE Instrument Bundle"
Description: """Transaction Bundle posted by the middleware to SENAITE containing all
Observations for a single ServiceRequest. Ensures atomic delivery — all Observations
succeed or fail together."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Identifier ---
* identifier 1..1 MS
* identifier ^short = "Unique identifier for this Bundle submission"

// --- Type ---
* type 1..1 MS
* type = #transaction (exactly)
* type ^short = "Always transaction for instrument result bundles"

// --- Timestamp ---
* timestamp 1..1 MS
* timestamp ^short = "Date and time the Bundle was created by the middleware"

// --- Entries (one per Observation) ---
* entry 1..* MS
* entry ^short = "One entry per Observation result for the ServiceRequest"
* entry.resource 1..1 MS
* entry.resource only SenaiteInstrumentObservation
* entry.request 1..1 MS
* entry.request.method 1..1 MS
* entry.request.method = #POST (exactly)
* entry.request.url 1..1 MS
* entry.request.url = "Observation" (exactly)

// --- Zero out unused elements ---
* entry.response 0..0
* entry.search 0..0
* entry.link 0..0
* total 0..0
* link 0..0
* signature 0..0
* issues 0..0
