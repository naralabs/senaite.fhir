Instance: example-patient
InstanceOf: SenaitePatient
Title: "[Patient] Example Jane Doe (Estimated BirthDate)"
Description: "Patient resource for Jane Doe with an estimated birth date indicated by the EstimatedDateBirth extension."
Usage: #example
* identifier.system = "http://hospital.senaite.com/patients"
* identifier.value = "123456"
* name.family = "Doe"
* name.given = "Jane"
* gender = #female
* birthDate = "1980-01-01"
* extension.url = "https://senaite.com/modelling/fhir/StructureDefinition/EstimatedDateBirth"
* extension.valueBoolean = true