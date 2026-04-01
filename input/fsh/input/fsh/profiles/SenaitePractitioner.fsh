// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaitePractitioner.fsh                                         │
// │  The Practitioner who orders the lab test                       │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaitePractitioner
Parent: Practitioner
Id: SenaitePractitioner
Title: "SENAITE Practitioner"
Description: "The Practitioner who orders the lab test via a SenaiteServiceRequest."
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Identifier ---
* identifier 1..* MS
* identifier ^short = "Practitioner identifier e.g. provider number"
* identifier.extension 0..0
* identifier.type 0..0
* identifier.period 0..0
* identifier.assigner 0..0

// --- Name ---
* name 1..1 MS
* name ^short = "Practitioner full name"

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* active 0..0
* telecom 0..0
* address 0..0
* gender 0..0
* birthDate 0..0
* deceased[x] 0..0
* photo 0..0
* qualification 0..0
* communication 0..0
