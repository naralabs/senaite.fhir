Extension: EstimatedDateBirth
Id: EstimatedDateBirth
Description: "If the date of birth is unknown to a high degree of precision"
Context: Patient
* ^version = "0.01"
* ^status = #draft
* . ..1
* . ^short = "If the date of birth was not known precisely"
* . ^definition = "true if the date of birth is unknown precisely"
* value[x] only boolean
* value[x] ^short = "Is the date of birth unknown for sure?"
* value[x] ^definition = "True if the date of birth is unknown"
* value[x] ^isModifierReason = "Date of birth is assumed to be precisely known"