// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteDevice.fsh                                               │
// │  Represents a lab instrument/analyser connected via middleware   │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteDevice
Parent: Device
Id: SenaiteDevice
Description: """Represents a laboratory instrument or analyser communicating with SENAITE
via a middleware layer (e.g. Open Integration Engine / Mirth Connect).
This resource is used to attribute results to a specific instrument and
to support audit and QC traceability."""
* ^status = #draft

// --- Identifiers ---
* identifier 1..1
* identifier.extension ..0
* identifier ^short = "Instrument serial number or asset ID"
* identifier.use = #official (exactly)
* identifier.type ..0
* identifier.system 1..
* identifier.system ^short = "Namespace for the instrument ID (e.g. institutional asset registry URI)"
* identifier.value 1..
* identifier.period ..0
* identifier.assigner ..0

// --- Status ---
* status 1..
* status ^short = "active | inactive"

// --- Type ---
* type 1..
* type ^short = "Kind of instrument (SNOMED preferred)"
* type.extension ..0
* type.coding 1..1
* type.coding.system = "http://snomed.info/sct" (exactly)
* type.coding.version ..0
* type.coding.code 1..
* type.coding.userSelected ..0

// --- Manufacturer details ---
* manufacturer 1..
* manufacturer ^short = "Instrument manufacturer name"
* modelNumber 1..
* modelNumber ^short = "Manufacturer model number"
* serialNumber ..0  // captured in identifier instead
* lotNumber ..0
* manufactureDate ..0
* expirationDate ..0
* name 1..1
* name.value 1..
* name.type = #registered-name (exactly)

// --- Strip unused elements ---
* definition ..0
* udiCarrier ..0
* version ..0
* property ..0
* patient ..0
* owner ..0
* contact ..0
* location ..0
* url ..0
* note ..0
* safety ..0
* parent ..0
