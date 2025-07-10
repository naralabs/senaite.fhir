Profile: SenaiteEncounter
Parent: Encounter
Id: SenaiteEncounter
* ^status = #draft
* extension ..0
* modifierExtension ..0
* identifier ..0
* status = #finished (exactly)
* status ^short = "finished "
* status ^definition = "We only want to be informed about finished encounters"
* statusHistory ..0
* class.extension ..0
* class.system from $v3-ActCode (preferred)
* class.version ..0
* class.userSelected ..0
* classHistory ..0
* type ..0
* serviceType ..0
* priority ..0
* subject ..0
* episodeOfCare ..0
* basedOn ..0
* participant ..0
* appointment ..0
* period ..0
* length ..0
* reasonCode ..0
* reasonReference ..0
* diagnosis ..0
* account ..0
* hospitalization ..0
* location.extension ..0
* location.modifierExtension ..0
* location.location ^definition = "The location where the encounter takes place. This will be used to determine where to send the results back to. If SENAITE does not recognise the location it will be created."
* location.location.extension ..0
* location.physicalType.coding from $location-physical-type (required)
* location.physicalType.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type" (exactly)
* location.physicalType.coding.version ..0
* serviceProvider.extension ..0
* serviceProvider.type = "Organization" (exactly)
* serviceProvider.identifier ..0
* partOf ..0