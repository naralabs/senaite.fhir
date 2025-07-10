Instance: example-servicerequest-2
InstanceOf: SenaiteServiceRequest
Usage: #example
* status = #active
* intent = #order
* category = $sct#108252007 "Laboratory procedure"
* category.text = "Laboratory procedure"
* code = $loinc#24357-6 "Urinalysis panel"
* code.text = "Urinalysis Panel"
* orderDetail[0] = $loinc#5804-0 "Leukocytes [Presence] in Urine by Test strip"
* orderDetail[+] = $loinc#5811-5 "Nitrite [Presence] in Urine by Test strip"
* orderDetail[+] = $loinc#5803-2 "Protein [Presence] in Urine by Test strip"
* orderDetail[+] = $loinc#5799-2 "Glucose [Presence] in Urine by Test strip"
* orderDetail[+] = $loinc#5807-3 "Blood [Presence] in Urine by Test strip"
* subject.reference = "Patient/example-patient"
* encounter.reference = "Encounter/example-encounter"
* requester.type = "Practitioner"
* requester.reference = "Practitioner/example-practitioner"
* specimen.reference = "Specimen/example-specimen"