Profile: SenaiteServiceRequest
Parent: ServiceRequest
Id: SenaiteServiceRequest
Description: """This will be an incoming lab request. It relies on references to:
- Specimen: to handle the related specimen details.
- Subject: The patient
- Organization: Determining from which client the request originated.
- Requester: The practitioner who made the request."""
* ^status = #draft

// ── Extensions ──────────────────────────────────────────────
// Remove all extensions except the new SenaiteClient one.
* extension contains SenaiteClient named client 1..1
* extension[client] ^short = "The submitting client organisation"

// Suppress all other extensions / modifier extensions
* modifierExtension ..0
* identifier ..0
* instantiatesCanonical ..0
* instantiatesUri ..0
* basedOn ..0
* replaces ..0
* requisition ..0
* status ^short = "draft | active | on-hold | revoked | entered-in-error"
* intent = #order (exactly)
* intent ^short = "order | reflex-order"
* category 1..1
* category ^definition = "This will always be a Laboratory procedure"
* category ^binding.valueSet = "http://hl7.org/fhir/ValueSet/servicerequest-category"
* category ^binding.strength = #required
* category.coding.system = "http://snomed.info/sct" (exactly)
* category.coding.system ^definition = "Always use SNOMED"
* category.coding.version ..0
* category.coding.code = #108252007 (exactly)
* category.coding.display = "Laboratory procedure" (exactly)
* category.coding.userSelected ..0
* category.text = "Laboratory procedure" (exactly)
* doNotPerform ..0
* code 1..
* code from $loinc (preferred)
* code ^binding.description = "For laboratory codes"
* code.extension ..0
* orderDetail ^definition = "Individual test codes that make up the ordered panel."
* orderDetail 0..
* orderDetail.extension ..0
* orderDetail.modifierExtension ..0
* orderDetail.parameterFocus ..0
* orderDetail.parameter 1..
* orderDetail.parameter.extension ..0
* orderDetail.parameter.modifierExtension ..0
* orderDetail.parameter.code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail.parameter.value[x] only CodeableConcept
* orderDetail.parameter.valueCodeableConcept from $loinc (preferred)
* orderDetail.parameter.valueCodeableConcept ^binding.description = "LOINC codes for individual laboratory tests"
* quantity[x] ..0
* subject.reference obeys subject-identified
* encounter ..0
* occurrence[x] ..0
* asNeeded[x] ..0
* requester.extension ..0
* requester.reference 1..
* requester.type 1..
* requester.type = "Practitioner" (exactly)
* requester.identifier ..0
* requester.display ..0
* performerType ..0
* performer ..0
* location ..0
* reason ..0
* insurance ..0
* supportingInfo ..0
* specimen 1..1
* specimen.reference 1..
* note.extension ..0
* patientInstruction ..0
* relevantHistory ..0