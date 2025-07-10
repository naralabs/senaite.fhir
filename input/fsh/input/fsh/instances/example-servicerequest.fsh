Instance: example-servicerequest
InstanceOf: SenaiteServiceRequest
Usage: #example
* status = #active
* intent = #order
* category = $sct#108252007 "Laboratory procedure"
* category.text = "Laboratory procedure"
* code = $loinc#57021-8 "CBC panel - Blood by Automated count"
* code.text = "Full Blood Count Panel"
* orderDetail[0] = $loinc#718-7 "Hemoglobin [Mass/volume] in Blood"
* orderDetail[+] = $loinc#789-8 "Erythrocytes [#/volume] in Blood"
* orderDetail[+] = $loinc#777-3 "Leukocytes [#/volume] in Blood"
* orderDetail[+] = $loinc#4544-3 "Platelets [#/volume] in Blood"
* subject.reference = "Patient/example-patient"
* encounter.reference = "Encounter/example-encounter"
* requester.type = "Practitioner"
* requester.reference = "Practitioner/example-practitioner"
* specimen.reference = "Specimen/example-specimen"