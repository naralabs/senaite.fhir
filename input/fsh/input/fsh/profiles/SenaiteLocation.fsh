// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteLocation.fsh                                             │
// │  Location from which the ServiceRequest was made                │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteLocation
Parent: Location
Id: SenaiteLocation
Title: "SENAITE Location"
Description: "Captures the location from which the ServiceRequest was made. Used to determine where results should be returned to."
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0
* ^purpose = "To determine where to send back the results for the ServiceRequest."

// --- Identifier ---
* identifier 1..* MS
* identifier ^short = "Unique identifier for the location"
* identifier.extension 0..0

// --- Name ---
* name 1..1 MS
* name ^short = "Human readable name of the location"

// --- Physical Type (R5: form replaces physicalType) ---
* form 0..1 MS
* form ^short = "Physical form of the location e.g. ward, department"
* form.extension 0..0
* form.coding 1..1 MS
* form.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type" (exactly)
* form.coding.version 0..0
* form.coding.userSelected 0..0

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* status 0..0
* operationalStatus 0..0
* alias 0..0
* description 0..0
* mode 0..0
* type 0..0
* contact 0..0
* address 0..0
* position 0..0
* managingOrganization 0..0
* partOf 0..0
* characteristic 0..0
* hoursOfOperation 0..0
* virtualService 0..0
* endpoint 0..0
