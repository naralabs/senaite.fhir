Instance: example-encounter-2
InstanceOf: SenaiteEncounter
Title: "[Encounter] Outpatient (Finished)"
Description: "A finished outpatient encounter occurring at a GP Office."
Usage: #example
* status = #completed
* class = $v3-ActCode#AMB "ambulatory"
* location.location.reference = "Location/example-location"
* serviceProvider.display = "GP Office"