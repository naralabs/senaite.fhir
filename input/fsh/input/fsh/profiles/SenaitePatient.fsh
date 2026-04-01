// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaitePatient.fsh                                              │
// │  Demographic details of the patient                             │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaitePatient
Parent: Patient
Id: SenaitePatient
Title: "SENAITE Patient"
Description: "Demographic details of the patient associated with a SenaiteServiceRequest."
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Extension ---
* extension contains EstimatedDateBirth named estimatedDateBirth 0..1
* extension[estimatedDateBirth] ^short = "Estimated date of birth if exact date is unknown"

// --- Identifier ---
* identifier 1..1 MS
* identifier ^short = "Unique patient identifier"
* identifier.extension 0..0
* identifier.value 1..1 MS
* identifier.period 0..0
* identifier.assigner 0..0

// --- Name ---
* name 1..* MS
* name ^short = "Patient name — at minimum family and given"

// --- Telecom ---
* telecom 0..* MS
* telecom.period 0..0

// --- Gender ---
* gender 1..1 MS
* gender ^short = "male | female | other | unknown"

// --- Birth Date ---
* birthDate 1..1 MS
* birthDate ^short = "Date of birth — may be estimated if EstimatedDateBirth extension is true"

// --- Deceased ---
* deceased[x] only dateTime
* deceased[x] ^short = "Date and time of death if applicable"

// --- Marital Status ---
* maritalStatus ^binding.strength = #required

// --- Zero out unused elements ---
* multipleBirth[x] 0..0
* photo 0..0
* contact 0..0
* communication 0..0
* generalPractitioner 0..0
* managingOrganization 0..0
* link 0..0
