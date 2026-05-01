Instance: example-servicerequest-2
InstanceOf: SenaiteServiceRequest
Title: "[ServiceRequest] Urinalysis"
Description: """
  ServiceRequest for a urinalysis panel. Client organisation is
  referenced directly via the SenaiteClient extension.
"""
Usage: #example

* extension[SenaiteClient].valueReference.reference = "Organization/micro-lab"

* status = #active
* intent = #order
* category = $sct#108252007 "Laboratory procedure"
* category.text = "Laboratory procedure"
* code.concept = $loinc#24357-6 "Urinalysis panel"

* orderDetail[0].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[0].parameter[0].valueCodeableConcept = $loinc#5804-0 "Leukocytes [Presence] in Urine by Test strip"
* orderDetail[1].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[1].parameter[0].valueCodeableConcept = $loinc#5811-5 "Nitrite [Presence] in Urine by Test strip"
* orderDetail[2].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[2].parameter[0].valueCodeableConcept = $loinc#5803-2 "Protein [Presence] in Urine by Test strip"
* orderDetail[3].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[3].parameter[0].valueCodeableConcept = $loinc#5799-2 "Glucose [Presence] in Urine by Test strip"
* orderDetail[4].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[4].parameter[0].valueCodeableConcept = $loinc#5807-3 "Blood [Presence] in Urine by Test strip"

* subject.reference = "Patient/example-patient"
* requester.type = "Practitioner"
* requester.reference = "Practitioner/example-practitioner"
* specimen.reference = "Specimen/example-specimen"