Profile: SenaitePatient
Parent: Patient
Id: SenaitePatient
Description: "Demographic details of the patient"
* ^status = #draft
* extension contains EstimatedDateBirth named estimatedDateBirth 0..*
* identifier 1..1
* identifier.extension ..0
* identifier.value 1..
* identifier.period ..0
* identifier.assigner ..0
* name 1..
* telecom.period ..0
* gender 1..
* birthDate 1..
* deceased[x] only dateTime
* maritalStatus ^binding.strength = #required
* multipleBirth[x] ..0
* photo ..0
* contact ..0
* communication ..0
* generalPractitioner ..0
* managingOrganization ..0