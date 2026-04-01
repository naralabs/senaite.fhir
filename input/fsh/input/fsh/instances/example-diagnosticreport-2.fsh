Instance: example-diagnosticreport-2
InstanceOf: SenaiteDiagnosticReport
Title: "[DiagnosticReport] Urinalysis Report (PDF)"
Description: "DiagnosticReport for a urinalysis panel represented as a PDF attached in presentedForm."
Usage: #example
* status = #final
* code.coding = $loinc#24357-6 "Urinalysis panel"
* code.text = "Urinalysis Panel"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* presentedForm.contentType = #application/pdf
* presentedForm.language = #en
* presentedForm.data = "JVBERi0xLjQKJcfs"