Instance: example-bundle
InstanceOf: SenaiteBundle
Title: "[Bundle] Instrument Observation Transaction"
Description: "Transaction Bundle containing an instrument observation posted by middleware."
Usage: #example
* id = "bundle-instrument-observation"
* identifier.system = "http://hospital.senaite.com/bundles"
* identifier.value = "BUNDLE-OBS-001"
* type = #transaction
* timestamp = "2025-07-01T09:20:00+00:00"
* entry[0].resource = Observation/instrument-obs-hb
* entry[0].request.method = #POST
* entry[0].request.url = "Observation"