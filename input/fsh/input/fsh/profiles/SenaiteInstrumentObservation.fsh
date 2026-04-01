// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteInstrumentObservation.fsh                                │
// │  Result produced by a lab instrument via middleware              │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteInstrumentObservation
Parent: Observation
Id: SenaiteInstrumentObservation
Description: """A quantitative or coded result produced by a laboratory instrument and
forwarded to SENAITE via middleware. Extends the base SenaiteObservation with
device attribution, specimen reference, reference ranges, and interpretation flags
(H/L/N/A) as returned by the analyser."""
* ^status = #draft

// --- Status ---
* status 1..
* status ^short = "registered | preliminary | final | amended | corrected | entered-in-error"

// --- Category ---
* category 1..1
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category" (exactly)
* category.coding.code = #laboratory (exactly)
* category.coding.display = "Laboratory" (exactly)

// --- Code (LOINC preferred) ---
* code 1..
* code.extension ..0
* code.coding 1..1
* code.coding.system from $loinc (preferred)
* code.coding.version ..0
* code.coding.code 1..
* code.coding.userSelected ..0

// --- Subject ---
* subject 1..
* subject only Reference(SenaitePatient)
* subject.reference 1..
* subject.identifier ..0
* subject.display ..0

// --- Links back to order and instrument ---
* basedOn 1..1
* basedOn only Reference(SenaiteServiceRequest)
* basedOn.reference 1..
* basedOn.identifier ..0
* basedOn.display ..0

* device 1..
* device only Reference(SenaiteDevice)
* device ^short = "The instrument that produced this result"
* device.reference 1..
* device.identifier ..0
* device.display ..0

* specimen 1..
* specimen only Reference(SenaiteSpecimen)
* specimen.reference 1..
* specimen.identifier ..0
* specimen.display ..0

// --- Result value ---
* value[x] 1..
* value[x] only Quantity or CodeableConcept or string
* valueQuantity.system = "http://unitsofmeasure.org" (exactly)
* valueQuantity.system ^short = "Always UCUM for instrument numeric results"
* valueQuantity.code 1..
* valueQuantity.unit 1..

// --- Interpretation (H/L/N/A flags from analyser) ---
* interpretation 0..1
* interpretation.extension ..0
* interpretation.coding 1..1
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation" (exactly)
* interpretation.coding.version ..0
* interpretation.coding.code 1..
* interpretation.coding.code ^short = "H | L | N | A | HH | LL"
* interpretation.coding.userSelected ..0

// --- Reference range (as returned by instrument) ---
* referenceRange 0..1
* referenceRange.extension ..0
* referenceRange.low ^short = "Lower bound of normal range"
* referenceRange.high ^short = "Upper bound of normal range"
* referenceRange.type ..0
* referenceRange.appliesTo ..0
* referenceRange.age ..0
* referenceRange.text ..0

// --- When result was produced ---
* effective[x] 1..
* effective[x] only dateTime
* effective[x] ^short = "DateTime the instrument produced the result"

// --- Strip unused elements ---
* extension ..0
* modifierExtension ..0
* identifier ..0
* partOf ..0
* focus ..0
* encounter ..0
* issued ..0
* performer ..0
* dataAbsentReason ..0
* bodyStructure ..0
* method ..0
* hasMember ..0
* derivedFrom ..0
* component ..0
