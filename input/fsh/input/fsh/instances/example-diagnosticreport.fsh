Instance: example-diagnosticreport
InstanceOf: SenaiteDiagnosticReport
Usage: #example
* status = #final
* code = $loinc#57021-8 "CBC panel - Blood by Automated count"
* code.text = "Full Blood Count Panel"
* subject.reference = "Patient/example-patient"
* basedOn.type = "Specimen"
* basedOn.reference = "Specimen/example-specimen"
* result[0].reference = "Observation/hb"
* result[+].reference = "Observation/rbc"
* result[+].reference = "Observation/wbc"
* result[+].reference = "Observation/plt"
* presentedForm.contentType = #application/pdf
* presentedForm.language = #en
* presentedForm.title = "CBC Report"
* presentedForm.data = "JVBERi0xLjQKJcfs"