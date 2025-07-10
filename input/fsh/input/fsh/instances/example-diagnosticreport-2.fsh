Instance: example-diagnosticreport-2
InstanceOf: SenaiteDiagnosticReport
Usage: #example
* status = #final
* code = $loinc#24357-6 "Urinalysis panel"
* code.text = "Urinalysis Panel"
* subject.reference = "Patient/example-patient"
* basedOn.reference = "ServiceRequest/example-servicerequest"
* presentedForm.contentType = #application/pdf
* presentedForm.title = "Urinalysis Report"
* presentedForm.language = #en
* presentedForm.data = "JVBERi0xLjQKJcfs"