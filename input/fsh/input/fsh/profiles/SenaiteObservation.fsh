// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteObservation.fsh                                          │
// │  Base observation profile for SENAITE results                   │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteObservation
Parent: Observation
Id: SenaiteObservation
Title: "SENAITE Observation"
Description: """Base observation profile for results produced within SENAITE.
SenaiteInstrumentObservation extends this profile for instrument-generated results."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Status ---
* status 1..1 MS
* status ^short = "registered | preliminary | final | amended | corrected | entered-in-error"

// --- Category ---
* category 1..1 MS
* category.coding 1..1 MS
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category" (exactly)
* category.coding.code = #laboratory (exactly)
* category.coding.display = "Laboratory" (exactly)

// --- Code ---
* code 1..1 MS
* code ^short = "LOINC code for the observation"
* code.extension 0..0
* code.coding 1..1 MS
* code.coding.system = "http://loinc.org" (exactly)
* code.coding.version 0..0
* code.coding.code 1..1 MS
* code.coding.userSelected 0..0

// --- Subject ---
* subject 1..1 MS
* subject only Reference(SenaitePatient)
* subject.reference 1..1 MS
* subject.identifier 0..0
* subject.display 0..0

// --- Based On ---
* basedOn 1..1 MS
* basedOn only Reference(SenaiteServiceRequest)
* basedOn ^short = "The ServiceRequest this observation fulfils"
* basedOn.reference 1..1 MS
* basedOn.identifier 0..0
* basedOn.display 0..0

// --- Effective ---
* effective[x] 1..1 MS
* effective[x] only dateTime
* effective[x] ^short = "Date and time the observation was made"

// --- Value ---
* value[x] 1..1 MS
* value[x] only Quantity or CodeableConcept or string
* valueQuantity.system = "http://unitsofmeasure.org" (exactly)
* valueQuantity.code 1..1 MS
* valueQuantity.unit 1..1 MS

// --- Interpretation ---
* interpretation 0..1 MS
* interpretation.extension 0..0
* interpretation.coding 1..1 MS
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation" (exactly)
* interpretation.coding.version 0..0
* interpretation.coding.code 1..1 MS
* interpretation.coding.code ^short = "H | L | N | A | HH | LL"
* interpretation.coding.userSelected 0..0

// --- Reference Range ---
* referenceRange 0..1 MS
* referenceRange.extension 0..0
* referenceRange.low ^short = "Lower bound of normal range"
* referenceRange.high ^short = "Upper bound of normal range"
* referenceRange.type 0..0
* referenceRange.appliesTo 0..0
* referenceRange.age 0..0
* referenceRange.text 0..0

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* identifier 0..0
* partOf 0..0
* focus 0..0
* encounter 0..0
* issued 0..0
* performer 0..0
* dataAbsentReason 0..0
* bodySite 0..0
* bodyStructure 0..0
* method 0..0
// specimen and device are zeroed in base but opened in SenaiteInstrumentObservation
* specimen 0..1
* device 0..1
* hasMember 0..0
* derivedFrom 0..0
* component 0..0
* instantiatesCanonical 0..0
* instantiatesReference 0..0
* triggeredBy 0..0
* note 0..0
