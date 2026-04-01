Instance: plt
InstanceOf: SenaiteObservation
Usage: #example
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding = $loinc#4544-3 "Platelets [#/volume] in Blood"
* code.text = "Platelets"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* effectiveDateTime = "2025-07-01T09:00:00+00:00"
* valueQuantity = 250 '10*9/L' "10^9/L"