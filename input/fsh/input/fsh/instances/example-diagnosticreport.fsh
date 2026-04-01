Instance: example-diagnosticreport
InstanceOf: SenaiteDiagnosticReport
Title: "[DiagnosticReport] CBC (PDF)"
Description: "DiagnosticReport for a Full Blood Count (CBC) panel with references to component Observations and an attached PDF."
Usage: #example
* status = #final
* code.coding = $loinc#57021-8 "CBC panel - Blood by Automated count"
* code.text = "Full Blood Count Panel"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* result[0].reference = "Observation/hb"
* result[+].reference = "Observation/rbc"
* result[+].reference = "Observation/wbc"
* result[+].reference = "Observation/plt"
* presentedForm.contentType = #application/pdf
* presentedForm.language = #en
* presentedForm.data = "JVBERi0xLjQKJcfs"