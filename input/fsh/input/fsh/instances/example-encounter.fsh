Instance: example-encounter
InstanceOf: SenaiteEncounter
Title: "[Encounter] Microbiology Lab"
Description: "Finished encounter associated with a visit to the outpatient lab, referencing the lab location and service provider."
Usage: #example
* status = #finished
* class = $v3-ActCode#AMB "ambulatory"
* location.location.reference = "Location/example-location"
* serviceProvider.reference = "Organization/micro-lab"
* serviceProvider.display = "Microbiology Laboratory"
* serviceProvider.type = "Organization"