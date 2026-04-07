Instance: example-servicerequest
InstanceOf: SenaiteServiceRequest
Title: "[ServiceRequest] CBC"
Description: "ServiceRequest for a Full Blood Count (CBC) panel including order details for component tests and specimen reference."
Usage: #example
* status = #active
* intent = #order
* category = $sct#108252007 "Laboratory procedure"
* category.text = "Laboratory procedure"
* code.concept = $loinc#57021-8 "CBC panel - Blood by Automated count"
* orderDetail[0].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[0].parameter[0].valueCodeableConcept = $loinc#718-7 "Hemoglobin [Mass/volume] in Blood"
* orderDetail[1].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[1].parameter[0].valueCodeableConcept = $loinc#789-8 "Erythrocytes [#/volume] in Blood"
* orderDetail[2].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[2].parameter[0].valueCodeableConcept = $loinc#777-3 "Leukocytes [#/volume] in Blood"
* orderDetail[3].parameter[0].code = http://terminology.hl7.org/CodeSystem/v3-ObservationValue#LOINC "Test Code"
* orderDetail[3].parameter[0].valueCodeableConcept = $loinc#4544-3 "Platelets [#/volume] in Blood"
* subject.reference = "Patient/example-patient"
* encounter.reference = "Encounter/example-encounter"
* requester.type = "Practitioner"
* requester.reference = "Practitioner/example-practitioner"
* specimen.reference = "Specimen/example-specimen"