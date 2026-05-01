Profile: SenaiteOrganization
Parent: Organization
Id: SenaiteOrganization
Description: "Used to specify the Organization who makes a SenaiteServiceRequest."
* ^status = #draft
* modifierExtension 0..0
* identifier 0..1
* identifier.extension 0..0
* identifier.value 1..
* identifier.period ..0
* identifier.assigner ..0
* name 1..1
* alias ..0
* partOf ..1 // this can be used in the future to express hierarchies if we need to know the requesting department
* endpoint ..0
