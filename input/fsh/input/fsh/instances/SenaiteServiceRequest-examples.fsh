// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteServiceRequest-examples.fsh                              │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Single test (haemoglobin only) ---
Instance: SenaiteServiceRequest-001
InstanceOf: SenaiteServiceRequest
Title: "ServiceRequest: Haemoglobin — James Nguyen"
Description: "Single test request for a haemoglobin measurement. No orderDetail required as no panel is involved."
* status = #active
* intent = #order
* category.coding.system = "http://snomed.info/sct"
* category.coding.code = #108252007
* category.coding.display = "Laboratory procedure"
* category.text = "Laboratory procedure"
* code.concept.coding.system = "http://loinc.org"
* code.concept.coding.code = #718-7
* code.concept.coding.display = "Hemoglobin [Mass/volume] in Blood"
* subject = Reference(SenaitePatient-001)
* encounter = Reference(SenaiteEncounter-001)
* requester = Reference(SenaitePractitioner-001)
* specimen = Reference(SenaiteSpecimen-001)

// --- Example 2: Full blood count panel with individual test codes ---
Instance: SenaiteServiceRequest-002
InstanceOf: SenaiteServiceRequest
Title: "ServiceRequest: Full Blood Count Panel — James Nguyen"
Description: "Panel request for a full blood count. Individual tests listed in orderDetail.parameterFocus."
* status = #active
* intent = #order
* category.coding.system = "http://snomed.info/sct"
* category.coding.code = #108252007
* category.coding.display = "Laboratory procedure"
* category.text = "Laboratory procedure"
* code.concept.coding.system = "http://loinc.org"
* code.concept.coding.code = #58410-2
* code.concept.coding.display = "CBC panel - Blood by Automated count"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #718-7
* orderDetail[=].parameterFocus.concept.coding.display = "Hemoglobin [Mass/volume] in Blood"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #718-7
* orderDetail[=].parameter[=].valueString = "Hemoglobin"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #6690-2
* orderDetail[=].parameterFocus.concept.coding.display = "Leukocytes [#/volume] in Blood by Automated count"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #6690-2
* orderDetail[=].parameter[=].valueString = "Leukocytes"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #777-3
* orderDetail[=].parameterFocus.concept.coding.display = "Platelets [#/volume] in Blood by Automated count"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #777-3
* orderDetail[=].parameter[=].valueString = "Platelets"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #4544-3
* orderDetail[=].parameterFocus.concept.coding.display = "Hematocrit [Volume Fraction] of Blood by Automated count"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #4544-3
* orderDetail[=].parameter[=].valueString = "Hematocrit"
* subject = Reference(SenaitePatient-001)
* encounter = Reference(SenaiteEncounter-001)
* requester = Reference(SenaitePractitioner-001)
* specimen = Reference(SenaiteSpecimen-001)

// --- Example 3: Liver function test panel ---
Instance: SenaiteServiceRequest-003
InstanceOf: SenaiteServiceRequest
Title: "ServiceRequest: Liver Function Test Panel — Maria Santos"
Description: "Panel request for a liver function test. Individual analytes listed in orderDetail.parameterFocus."
* status = #active
* intent = #order
* category.coding.system = "http://snomed.info/sct"
* category.coding.code = #108252007
* category.coding.display = "Laboratory procedure"
* category.text = "Laboratory procedure"
* code.concept.coding.system = "http://loinc.org"
* code.concept.coding.code = #24325-3
* code.concept.coding.display = "Hepatic function panel"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #1742-6
* orderDetail[=].parameterFocus.concept.coding.display = "Alanine aminotransferase [Enzymatic activity/volume] in Serum or Plasma"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #1742-6
* orderDetail[=].parameter[=].valueString = "ALT"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #1920-8
* orderDetail[=].parameterFocus.concept.coding.display = "Aspartate aminotransferase [Enzymatic activity/volume] in Serum or Plasma"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #1920-8
* orderDetail[=].parameter[=].valueString = "AST"
* orderDetail[+].parameterFocus.concept.coding.system = "http://loinc.org"
* orderDetail[=].parameterFocus.concept.coding.code = #1975-2
* orderDetail[=].parameterFocus.concept.coding.display = "Bilirubin.total [Mass/volume] in Serum or Plasma"
* orderDetail[=].parameter[+].code.coding.system = "http://loinc.org"
* orderDetail[=].parameter[=].code.coding.code = #1975-2
* orderDetail[=].parameter[=].valueString = "Total Bilirubin"
* subject = Reference(SenaitePatient-002)
* encounter = Reference(SenaiteEncounter-003)
* requester = Reference(SenaitePractitioner-002)
* specimen = Reference(SenaiteSpecimen-003)
* note.text = "Patient on hepatotoxic medication — urgent review requested"
