Instance: example-servicerequest-2
InstanceOf: SenaiteServiceRequest
Title: "[ServiceRequest] Urinalysis"
Description: "ServiceRequest for a urinalysis panel including multiple orderDetail codes for individual urine tests."
Usage: #example
* status = #active
* intent = #order
* category.coding.system = "http://snomed.info/sct"
* category.coding.code = #108252007
* category.coding.display = "Laboratory procedure"
* category.text = "Laboratory procedure"
* code.concept.coding = $loinc#24357-6 "Urinalysis panel"
* code.concept.text = "Urinalysis Panel"
* orderDetail[0].parameterFocus.concept.coding = $loinc#5804-0 "Leukocytes [Presence] in Urine by Test strip"
* orderDetail[1].parameterFocus.concept.coding = $loinc#5811-5 "Nitrite [Presence] in Urine by Test strip"
* orderDetail[2].parameterFocus.concept.coding = $loinc#5803-2 "Protein [Presence] in Urine by Test strip"
* orderDetail[3].parameterFocus.concept.coding = $loinc#5799-2 "Glucose [Presence] in Urine by Test strip"
* orderDetail[4].parameterFocus.concept.coding = $loinc#5807-3 "Blood [Presence] in Urine by Test strip"
* subject.reference = "Patient/example-patient"
* encounter.reference = "Encounter/example-encounter"
* requester.type = "Practitioner"
* requester.reference = "Practitioner/example-practitioner"
* specimen.reference = "Specimen/example-specimen"