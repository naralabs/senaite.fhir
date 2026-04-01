// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteInstrumentObservation-examples.fsh                       │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Haemoglobin from Sysmex XN-1000 (normal) ---
Instance: SenaiteInstrumentObservation-001
InstanceOf: SenaiteInstrumentObservation
Title: "Instrument Observation: Haemoglobin — Sysmex XN-1000 (normal)"
Description: "Haemoglobin result produced by the Sysmex XN-1000, corresponding to an FBC panel orderDetail."
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding.system = "http://loinc.org"
* code.coding.code = #718-7
* code.coding.display = "Hemoglobin [Mass/volume] in Blood"
* subject = Reference(SenaitePatient-001)
* basedOn = Reference(SenaiteServiceRequest-002)
* effectiveDateTime = "2024-11-01T10:15:00Z"
* valueQuantity.value = 148
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
* device = Reference(SenaiteDevice-001)
* specimen = Reference(SenaiteSpecimen-001)

// --- Example 2: Platelet count from Sysmex XN-1000 (low) ---
Instance: SenaiteInstrumentObservation-002
InstanceOf: SenaiteInstrumentObservation
Title: "Instrument Observation: Platelet Count — Sysmex XN-1000 (low)"
Description: "Platelet count result below the lower limit of normal, flagged by the instrument."
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding.system = "http://loinc.org"
* code.coding.code = #777-3
* code.coding.display = "Platelets [#/volume] in Blood by Automated count"
* subject = Reference(SenaitePatient-001)
* basedOn = Reference(SenaiteServiceRequest-002)
* effectiveDateTime = "2024-11-01T10:15:00Z"
* valueQuantity.value = 88
* valueQuantity.unit = "10*9/L"
* valueQuantity.system = "http://unitsofmeasure.org"
* valueQuantity.code = #10*9/L
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation"
* interpretation.coding.code = #L
* interpretation.coding.display = "Low"
* referenceRange.low.value = 150
* referenceRange.low.unit = "10*9/L"
* referenceRange.high.value = 400
* referenceRange.high.unit = "10*9/L"
* device = Reference(SenaiteDevice-001)
* specimen = Reference(SenaiteSpecimen-001)

// --- Example 3: ALT from Roche Cobas c502 (critically high) ---
Instance: SenaiteInstrumentObservation-003
InstanceOf: SenaiteInstrumentObservation
Title: "Instrument Observation: ALT — Roche Cobas c502 (critically high)"
Description: "Alanine aminotransferase result critically elevated, flagged HH by the Cobas analyser."
* status = #final
* category.coding.system = "http://terminology.hl7.org/CodeSystem/observation-category"
* category.coding.code = #laboratory
* category.coding.display = "Laboratory"
* code.coding.system = "http://loinc.org"
* code.coding.code = #1742-6
* code.coding.display = "Alanine aminotransferase [Enzymatic activity/volume] in Serum or Plasma"
* subject = Reference(SenaitePatient-002)
* basedOn = Reference(SenaiteServiceRequest-003)
* effectiveDateTime = "2024-11-03T08:30:00Z"
* valueQuantity.value = 412
* valueQuantity.unit = "U/L"
* valueQuantity.system = "http://unitsofmeasure.org"
* valueQuantity.code = #U/L
* interpretation.coding.system = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation"
* interpretation.coding.code = #HH
* interpretation.coding.display = "Critical high"
* referenceRange.low.value = 7
* referenceRange.low.unit = "U/L"
* referenceRange.high.value = 56
* referenceRange.high.unit = "U/L"
* device = Reference(SenaiteDevice-002)
* specimen = Reference(SenaiteSpecimen-003)
