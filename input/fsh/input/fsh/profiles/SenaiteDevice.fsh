Profile: SenaiteDevice
Parent: Device
Id: SenaiteDevice
Title: "Senaite Device"
Description: """Represents a laboratory instrument that produces results in SENAITE.
Used to identify the source instrument of an Observation, supporting
multi-device labs and enabling per-instrument QC and audit trails.
If SENAITE does not recognise the device identifier it will be created
using the supplied fields."""
* ^status = #draft
* extension ..0
* modifierExtension ..0

// Asset number — the instrument's ID in the lab's asset register.
// Used by SENAITE to identify or auto-create the device record.
* identifier 1..1
* identifier.extension ..0
* identifier.value 1..
* identifier.period ..0
* identifier.assigner ..0

// Human-readable instrument name e.g. "Sysmex XN-1000 #2"
* displayName 1..1

// Manufacturer name e.g. "Sysmex"
* manufacturer 0..1

// Model number e.g. "XN-1000"
* modelNumber 0..1

// Serial number — the physically unique instrument identifier
* serialNumber 0..1

// Suppress everything else
* udiCarrier ..0
* status ..0
* availabilityStatus ..0
* biologicalSourceEvent ..0
* manufactureDate ..0
* expirationDate ..0
* lotNumber ..0
* name ..0
* partNumber ..0
* category ..0
* type ..0
* version ..0
* conformsTo ..0
* property ..0
* mode ..0
* cycle ..0
* duration ..0
* owner ..0
* contact ..0
* location ..0
* url ..0
* endpoint ..0
* gateway ..0
* note ..0
* safety ..0
* parent ..0