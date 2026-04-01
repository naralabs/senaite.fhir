Instance: hb
InstanceOf: SenaiteObservation
Usage: #example
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding = $loinc#718-7 "Hemoglobin [Mass/volume] in Blood"
* code.text = "Hemoglobin"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* effectiveDateTime = "2025-07-01T09:00:00+00:00"
* valueQuantity = 13.5 'g/dL' "g/dL"