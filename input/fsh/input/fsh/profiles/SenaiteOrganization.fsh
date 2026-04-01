// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteOrganization.fsh                                         │
// │  Organization associated with a SenaiteServiceRequest           │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteOrganization
Parent: Organization
Id: SenaiteOrganization
Title: "SENAITE Organization"
Description: "The Organization associated with a SenaiteServiceRequest, typically referenced via a SenaiteEncounter."
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Identifier ---
* identifier 0..1 MS
* identifier ^short = "Organization identifier"
* identifier.extension 0..0
* identifier.value 1..1 MS
* identifier.period 0..0
* identifier.assigner 0..0

// --- Name ---
* name 1..1 MS
* name ^short = "Name of the organization"

// --- Contact (R5: telecom and address moved into contact backbone) ---
* contact 0..1 MS
* contact ^short = "Contact details for the organization"
* contact.telecom 0..* MS
* contact.telecom.system 1..1 MS
* contact.telecom.value 1..1 MS
* contact.telecom.use 0..0
* contact.telecom.rank 0..0
* contact.telecom.period 0..0
* contact.address 0..1 MS
* contact.address.line 0..* MS
* contact.address.city 0..1 MS
* contact.address.state 0..1 MS
* contact.address.postalCode 0..1 MS
* contact.address.country 0..0
* contact.address.use 0..0
* contact.address.type 0..0
* contact.address.period 0..0

// --- Zero out unused elements ---
* modifierExtension 0..0
* active 0..0
* type 0..0
* alias 0..0
* description 0..0
* partOf 0..0
* endpoint 0..0
* qualification 0..0
