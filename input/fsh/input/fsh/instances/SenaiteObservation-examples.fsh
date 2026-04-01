// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteObservation-examples.fsh                                 │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Haemoglobin result (normal) ---
Instance: SenaiteObservation-001
InstanceOf: SenaiteObservation
Title: "Observation: Haemoglobin — James Nguyen (normal)"
Description: "Haemoglobin result within normal range, manually entered in SENAITE."
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding.system = "http://loinc.org"
* code.coding.code = #718-7
* code.coding.display = "Hemoglobin [Mass/volume] in Blood"
* subject = Reference(SenaitePatient-001)
* basedOn = Reference(SenaiteServiceRequest-001)
* effectiveDateTime = "2024-11-01T10:30:00Z"
* valueQuantity.value = 145
* valueQuantity.unit = "g/L"
* valueQuantity.system = "http://unitsofmeasure.org"
* valueQuantity.code = #g/L
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation"
* interpretation.coding.code = #N
* interpretation.coding.display = "Normal"
* referenceRange.low.value = 130
* referenceRange.low.unit = "g/L"
* referenceRange.high.value = 175
* referenceRange.high.unit = "g/L"

// --- Example 2: ALT result (high) ---
Instance: SenaiteObservation-002
InstanceOf: SenaiteObservation
Title: "Observation: ALT — Maria Santos (high)"
Description: "Alanine aminotransferase result above the upper limit of normal."
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding.system = "http://loinc.org"
* code.coding.code = #1742-6
* code.coding.display = "Alanine aminotransferase [Enzymatic activity/volume] in Serum or Plasma"
* subject = Reference(SenaitePatient-002)
* basedOn = Reference(SenaiteServiceRequest-003)
* effectiveDateTime = "2024-11-02T11:00:00Z"
* valueQuantity.value = 98
* valueQuantity.unit = "U/L"
* valueQuantity.system = "http://unitsofmeasure.org"
* valueQuantity.code = #U/L
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation"
* interpretation.coding.code = #H
* interpretation.coding.display = "High"
* referenceRange.low.value = 7
* referenceRange.low.unit = "U/L"
* referenceRange.high.value = 56
* referenceRange.high.unit = "U/L"

// --- Example 3: Coded (qualitative) result ---
Instance: SenaiteObservation-003
InstanceOf: SenaiteObservation
Title: "Observation: Urine Culture — Maria Santos (negative)"
Description: "Qualitative urine culture result returned as a CodeableConcept."
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding.system = "http://loinc.org"
* code.coding.code = #630-4
* code.coding.display = "Bacteria identified in Urine by Culture"
* subject = Reference(SenaitePatient-002)
* basedOn = Reference(SenaiteServiceRequest-003)
* effectiveDateTime = "2024-11-02T14:00:00Z"
* valueCodeableConcept.coding.system = "http://snomed.info/sct"
* valueCodeableConcept.coding.code = #260385009
* valueCodeableConcept.coding.display = "Negative"
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation"
* interpretation.coding.code = #N
* interpretation.coding.display = "Normal"
