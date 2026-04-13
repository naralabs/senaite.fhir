Alias: $loinc = http://loinc.org
Alias: $sct   = http://snomed.info/sct

// ============================================================
// Devices
// ============================================================

// ------------------------------------------------------------
// Haematology analyser — Sysmex XN-1000
// Used for CBC (full blood count) results
// ------------------------------------------------------------
Instance: device-sysmex-xn1000
InstanceOf: SenaiteDevice
Title: "[Device] Sysmex XN-1000"
Description: "Haematology analyser used for full blood count panels."
Usage: #example
* identifier.system = "http://lab.senaite.com/devices"
* identifier.value  = "ASSET-HAE-001"
* displayName       = "Sysmex XN-1000 #1"
* manufacturer      = "Sysmex"
* modelNumber       = "XN-1000"
* serialNumber      = "SN-XN1000-20394"


// ------------------------------------------------------------
// Chemistry analyser — Roche Cobas c502
// Used for liver panel / biochemistry results
// ------------------------------------------------------------
Instance: device-roche-cobas-c502
InstanceOf: SenaiteDevice
Title: "[Device] Roche Cobas c502"
Description: "Chemistry analyser used for liver panel and general biochemistry panels."
Usage: #example
* identifier.system = "http://lab.senaite.com/devices"
* identifier.value  = "ASSET-CHEM-001"
* displayName       = "Roche Cobas c502 #1"
* manufacturer      = "Roche"
* modelNumber       = "Cobas c502"
* serialNumber      = "SN-C502-49571"
