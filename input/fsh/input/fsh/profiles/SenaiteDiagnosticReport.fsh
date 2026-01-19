Profile: SenaiteDiagnosticReport
Parent: DiagnosticReport
Id: SenaiteDiagnosticReport
Description: """This is the results for the lab test requested by the ServiceRequest - as such it requires a basedOn link to the Service Request.
It may contain either the pdf file in presentedForm or the quanititative results as Observations in results."""
* ^status = #draft
* extension ..0
* modifierExtension ..0
* identifier ..0
* basedOn 1..1
* basedOn.extension ..0
* basedOn.reference 1..
* basedOn.identifier ..0
* basedOn.display ..0
* status ^definition = "The status of the diagnostic report.\r\nAccepts: registered | partial | preliminary | final | entered-in-error"
* code.extension ..0
* code.coding.extension ..0
* code.coding.system from $loinc (preferred)
* code.coding.version ..0
* code.coding.userSelected ..0
* subject.extension ..0
* subject.type = "Patient" (exactly)
* subject.identifier ..0
* encounter ..0
* effective[x] ..0
* issued ..0
* performer ..0
* resultsInterpreter ..0
* specimen ..0
* result.extension ..0
* result.type ..0
* result.identifier ..0
* result.reference 0..
* imagingStudy ..0
* media ..0
* conclusionCode ..0
* presentedForm ..1
* presentedForm.extension ..0
* presentedForm.contentType = #application/pdf (exactly)
* presentedForm.data 1..
* presentedForm.url ..0
* presentedForm.size ..0
* presentedForm.hash ..0