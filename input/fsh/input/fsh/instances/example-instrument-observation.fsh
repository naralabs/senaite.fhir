Instance: example-instrument-observation
InstanceOf: SenaiteInstrumentObservation
Title: "[Observation] CBC Hemoglobin Instrument Result"
Description: "Instrument-generated hemoglobin result for the CBC panel."
Usage: #example
* id = "instrument-obs-hb"
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding = $loinc#718-7 "Hemoglobin [Mass/volume] in Blood"
* code.text = "Hemoglobin"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* effectiveDateTime = "2025-07-01T09:15:00+00:00"
* valueQuantity = 13.5 'g/dL' "g/dL"
* device.reference = "Device/example-device"
* specimen.reference = "Specimen/example-specimen"