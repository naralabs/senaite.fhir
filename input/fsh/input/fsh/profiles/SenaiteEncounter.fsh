Profile: SenaiteEncounter
Parent: Encounter
Id: SenaiteEncounter
* ^status = #draft
* extension ..0
* modifierExtension ..0
* identifier ..0
* status = #completed (exactly)
* status ^short = "completed"
* status ^definition = "We only want to be informed about finished encounters"
* class from $v3-ActCode (preferred)
* type ..0
* serviceType ..0
* priority ..0
* subject ..0
* episodeOfCare ..0
* basedOn ..0
* participant ..0
* appointment ..0
* actualPeriod ..0
* length ..0
* reason ..0
* diagnosis ..0
* account ..0
* admission ..0
* location.extension ..0
* location.modifierExtension ..0
* location.location ^definition = "The location where the encounter takes place. This will be used to determine where to send the results back to. If SENAITE does not recognise the location it will be created."
* location.location.extension ..0
* location.form from $location-physical-type (required)
* location.form.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type" (exactly)
* location.form.coding.version ..0
* serviceProvider only Reference(SenaiteOrganization)
* partOf ..0