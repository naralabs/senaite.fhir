// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteSpecimen.fsh                                             │
// │  Specimen accompanying the ServiceRequest                       │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteSpecimen
Parent: Specimen
Id: SenaiteSpecimen
Title: "SENAITE Specimen"
Description: "The specimen accompanying a SenaiteServiceRequest."
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Type ---
* type 1..1 MS
* type ^short = "Type of specimen e.g. blood, urine — SNOMED preferred"
* type.extension 0..0
* type.coding 1..1 MS
* type.coding from $sct (preferred)
* type.coding.extension 0..0
* type.coding.version 0..0
* type.coding.userSelected 0..0

// --- Subject ---
* subject 1..1 MS
* subject only Reference(SenaitePatient)
* subject ^short = "The patient this specimen was collected from"
* subject.reference 1..1 MS
* subject.identifier 0..0
* subject.display 0..0

// --- Collection ---
* collection 0..1 MS
* collection ^short = "Details of specimen collection"
* collection.collected[x] only dateTime
* collection.collected[x] ^short = "Date and time of collection"
* collection.duration 0..0
* collection.quantity 0..0
* collection.method 0..0
* collection.device 0..0
* collection.procedure 0..0
* collection.bodySite 0..0
* collection.fastingStatus[x] 0..0

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* identifier 0..0
* accessionIdentifier 0..0
* status 0..0
* receivedTime 0..0
* parent 0..0
* request 0..0
* combined 0..0
* role 0..0
* feature 0..0
* processing 0..0
* container 0..0
* condition 0..0
* note 0..0
