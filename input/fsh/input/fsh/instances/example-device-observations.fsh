Alias: $loinc = http://loinc.org
Alias: $sct   = http://snomed.info/sct

// ============================================================
// Observations — CBC results from Sysmex XN-1000
// basedOn references example-servicerequest (CBC)
// device references device-sysmex-xn1000
// ============================================================

Instance: hb-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] Hemoglobin (instrument)"
Description: "Hemoglobin result pushed by the Sysmex XN-1000 for the CBC ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#718-7 "Hemoglobin [Mass/volume] in Blood"
* code.text               = "Hemoglobin"
* valueQuantity           = 13.5 'g/dL' "g/dL"
* basedOn.reference       = "ServiceRequest/example-servicerequest"
* device = Reference(device-sysmex-xn1000)

Instance: rbc-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] Red Blood Cells (instrument)"
Description: "Red blood cell count pushed by the Sysmex XN-1000 for the CBC ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#789-8 "Erythrocytes [#/volume] in Blood"
* code.text               = "Red Blood Cells"
* valueQuantity           = 4.7 '10*12/L' "10^12/L"
* basedOn.reference       = "ServiceRequest/example-servicerequest"
* device = Reference(device-sysmex-xn1000)

Instance: wbc-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] White Blood Cells (instrument)"
Description: "White blood cell count pushed by the Sysmex XN-1000 for the CBC ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#777-3 "Leukocytes [#/volume] in Blood"
* code.text               = "White Blood Cells"
* valueQuantity           = 6.2 '10*9/L' "10^9/L"
* basedOn.reference       = "ServiceRequest/example-servicerequest"
* device = Reference(device-sysmex-xn1000)

Instance: plt-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] Platelets (instrument)"
Description: "Platelet count pushed by the Sysmex XN-1000 for the CBC ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#4544-3 "Platelets [#/volume] in Blood"
* code.text               = "Platelets"
* valueQuantity           = 250 '10*9/L' "10^9/L"
* basedOn.reference       = "ServiceRequest/example-servicerequest"
* device = Reference(device-sysmex-xn1000)


// ============================================================
// Observations — Liver panel results from Roche Cobas c502
// basedOn references LiverPanelServiceRequest
// device references device-roche-cobas-c502
// ============================================================

Instance: alt-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] ALT (instrument)"
Description: "Alanine aminotransferase result pushed by the Roche Cobas c502 for the liver panel ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#1742-6 "ALT [Enzymatic activity/volume] in Serum or Plasma"
* code.text               = "ALT"
* valueQuantity           = 32 'U/L' "U/L"
* basedOn.reference       = "ServiceRequest/LiverPanelServiceRequest"
* device = Reference(device-roche-cobas-c502)

Instance: ast-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] AST (instrument)"
Description: "Aspartate aminotransferase result pushed by the Roche Cobas c502 for the liver panel ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#1920-8 "AST [Enzymatic activity/volume] in Serum or Plasma"
* code.text               = "AST"
* valueQuantity           = 28 'U/L' "U/L"
* basedOn.reference       = "ServiceRequest/LiverPanelServiceRequest"
* device = Reference(device-roche-cobas-c502)

Instance: alp-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] ALP (instrument)"
Description: "Alkaline phosphatase result pushed by the Roche Cobas c502 for the liver panel ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#6768-6 "Alkaline phosphatase [Enzymatic activity/volume] in Serum or Plasma"
* code.text               = "ALP"
* valueQuantity           = 74 'U/L' "U/L"
* basedOn.reference       = "ServiceRequest/LiverPanelServiceRequest"
* device = Reference(device-roche-cobas-c502)

Instance: tbil-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] Total Bilirubin (instrument)"
Description: "Total bilirubin result pushed by the Roche Cobas c502 for the liver panel ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#1975-2 "Bilirubin.total [Mass/volume] in Serum or Plasma"
* code.text               = "Total Bilirubin"
* valueQuantity           = 10 'umol/L' "umol/L"
* basedOn.reference       = "ServiceRequest/LiverPanelServiceRequest"
* device = Reference(device-roche-cobas-c502)

Instance: albumin-instrument
InstanceOf: SenaiteObservation
Title: "[Observation] Albumin (instrument)"
Description: "Albumin result pushed by the Roche Cobas c502 for the liver panel ServiceRequest."
Usage: #example
* status                  = #final
* code                    = $loinc#1751-7 "Albumin [Mass/volume] in Serum or Plasma"
* code.text               = "Albumin"
* valueQuantity           = 42 'g/L' "g/L"
* basedOn.reference       = "ServiceRequest/LiverPanelServiceRequest"
* device = Reference(device-roche-cobas-c502)
