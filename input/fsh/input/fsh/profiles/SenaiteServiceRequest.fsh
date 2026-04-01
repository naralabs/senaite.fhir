// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteServiceRequest.fsh                                       │
// │  Incoming lab request                                           │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteServiceRequest
Parent: ServiceRequest
Id: SenaiteServiceRequest
Title: "SENAITE Service Request"
Description: """Incoming lab request to SENAITE. The code represents the ordered panel or test.
Where a panel is ordered, orderDetail.parameterFocus carries the individual test codes.
References SenaitePatient, SenaiteSpecimen, SenaiteEncounter, and SenaitePractitioner."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Status ---
* status 1..1 MS
* status ^short = "draft | active | on-hold | revoked | entered-in-error"

// --- Intent ---
* intent 1..1 MS
* intent = #order (exactly)
* intent ^short = "order | reflex-order"

// --- Category ---
* category 1..1 MS
* category ^definition = "Always a Laboratory procedure"
* category.coding 1..1 MS
* category.coding.system = "http://snomed.info/sct" (exactly)
* category.coding.version 0..0
* category.coding.code = #108252007 (exactly)
* category.coding.display = "Laboratory procedure" (exactly)
* category.coding.userSelected 0..0
* category.text = "Laboratory procedure" (exactly)

// --- Code (panel or single test) ---
// R5: ServiceRequest.code is CodeableReference — constrain via .concept
* code 1..1 MS
* code ^short = "LOINC code for the ordered panel or test"
* code ^definition = "The panel or test being ordered. Where a panel is ordered, individual tests are specified in orderDetail.parameterFocus."
* code.extension 0..0
* code.concept 1..1 MS
* code.concept.coding 1..1 MS
* code.concept.coding.system = "http://loinc.org" (exactly)
* code.concept.coding.code 1..1 MS
* code.concept.coding.version 0..0
* code.concept.coding.userSelected 0..0

// --- Order Detail (R5 backbone: individual test codes within a panel) ---
* orderDetail 0..* MS
* orderDetail ^short = "Individual test codes within the ordered panel"
* orderDetail ^definition = "Where a panel is ordered in code, each individual test to be performed is listed here using parameter with a LOINC code."
* orderDetail.extension 0..0
* orderDetail.parameter 1..1 MS
* orderDetail.parameter ^short = "LOINC code for the individual test"
* orderDetail.parameter.code 1..1 MS
* orderDetail.parameter.code.coding 1..1 MS
* orderDetail.parameter.code.coding.system = "http://loinc.org" (exactly)
* orderDetail.parameter.code.coding.code 1..1 MS
* orderDetail.parameter.code.coding.version 0..0
* orderDetail.parameter.code.coding.userSelected 0..0

// --- Subject ---
* subject 1..1 MS
* subject only Reference(SenaitePatient)
* subject ^short = "The patient the test is for"
* subject.reference obeys subject-identified
* subject.identifier 0..0
* subject.display 0..0

// --- Encounter ---
* encounter 1..1 MS
* encounter only Reference(SenaiteEncounter)
* encounter ^short = "The encounter that triggered this request"
* encounter.reference 1..1 MS
* encounter.type 0..0
* encounter.identifier 0..0
* encounter.display 0..0

// --- Requester ---
* requester 1..1 MS
* requester only Reference(SenaitePractitioner)
* requester ^short = "The practitioner who made the request"
* requester.extension 0..0
* requester.reference 1..1 MS
* requester.type = "Practitioner" (exactly)
* requester.identifier 0..0
* requester.display 0..0

// --- Specimen ---
* specimen 1..1 MS
* specimen only Reference(SenaiteSpecimen)
* specimen ^short = "The specimen to be analysed"
* specimen.reference 1..1 MS

// --- Note ---
* note 0..1 MS
* note ^short = "Optional free text note accompanying the request"
* note.extension 0..0

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* identifier 0..0
* instantiatesCanonical 0..0
* instantiatesUri 0..0
* basedOn 0..0
* replaces 0..0
* requisition 0..0
* doNotPerform 0..0
* quantity[x] 0..0
* occurrence[x] 0..0
* asNeeded[x] 0..0
* performerType 0..0
* performer 0..0
* location 0..0
* reason 0..0
* insurance 0..0
* supportingInfo 0..0
* patientInstruction 0..0
* relevantHistory 0..0
* priority 0..0
