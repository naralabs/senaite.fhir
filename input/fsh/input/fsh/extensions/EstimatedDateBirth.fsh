// ╭──────────────────────────────────────────────────────────────────╮
// │  EstimatedDateBirth.fsh                                          │
// │  Extension for estimated date of birth                          │
// ╰──────────────────────────────────────────────────────────────────╯

Extension: EstimatedDateBirth
Id: EstimatedDateBirth
Title: "Estimated Date of Birth"
Description: "Indicates whether the patient's date of birth is an estimate rather than precisely known."
* ^version = "1.0.0"
* ^status = #draft
* ^fhirVersion = #5.0.0
* ^context[+].type = #element
* ^context[=].expression = "Patient"

* . 0..1
* . ^short = "Date of birth is estimated"
* . ^definition = "Set to true if the date of birth is not precisely known."

* value[x] only boolean
* value[x] 1..1
* value[x] ^short = "True if the date of birth is an estimate"
* value[x] ^definition = "True if the date of birth is unknown precisely."
* value[x] ^isModifierReason = "Date of birth is assumed to be precisely known unless this extension is present and true."
