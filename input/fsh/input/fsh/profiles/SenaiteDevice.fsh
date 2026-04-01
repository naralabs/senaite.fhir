// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteDevice.fsh                                               │
// │  Laboratory instrument connected via middleware                 │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteDevice
Parent: Device
Id: SenaiteDevice
Title: "SENAITE Device"
Description: """Represents a laboratory instrument or analyser communicating with SENAITE
via a middleware layer. Used to attribute results to a specific instrument and
to support audit and QC traceability."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Identifier ---
* identifier 1..* MS
* identifier ^short = "Unique identifier for the instrument"

// --- Status ---
* status 1..1 MS
* status = #active (exactly)
* status ^short = "Always active for registered instruments"

// --- Display Name ---
* displayName 1..1 MS
* displayName ^short = "Human readable name of the instrument"

// --- Manufacturer ---
* manufacturer 0..1 MS
* manufacturer ^short = "Instrument manufacturer name"

// --- Model Number ---
* modelNumber 0..1 MS
* modelNumber ^short = "Instrument model number"

// --- Serial Number ---
* serialNumber 0..1 MS
* serialNumber ^short = "Instrument serial number"

// --- Location ---
* location 0..1 MS
* location only Reference(SenaiteLocation)
* location ^short = "Physical location of the instrument in the lab"

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* udiCarrier 0..0
* availabilityStatus 0..0
* biologicalSourceEvent 0..0
* property 0..0
* mode 0..0
* cycle 0..0
* duration 0..0
* contact 0..0
* endpoint 0..0
* gateway 0..0
* note 0..0
* safety 0..0
* parent 0..0
* definition 0..0
* version 0..0
* conformsTo 0..0
* name 0..0
* type 0..0
