Instance: rbc
InstanceOf: SenaiteObservation
Usage: #example
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding = $loinc#789-8 "Erythrocytes [#/volume] in Blood"
* code.text = "Red Blood Cells"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* effectiveDateTime = "2025-07-01T09:00:00+00:00"
* valueQuantity = 4.7 '10*12/L' "10^12/L"