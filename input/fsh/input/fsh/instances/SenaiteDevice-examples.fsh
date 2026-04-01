// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteDevice-examples.fsh                                      │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Haematology analyser ---
Instance: SenaiteDevice-001
InstanceOf: SenaiteDevice
Title: "Device: Sysmex XN-1000 Haematology Analyser"
Description: "Automated haematology analyser producing full blood count results."
* identifier.system = "http://senaite.example.org/device-id"
* identifier.value = "DEV-001"
* status = #active
* displayName = "Sysmex XN-1000"
* manufacturer = "Sysmex Corporation"
* modelNumber = "XN-1000"
* serialNumber = "SYS-XN-20240101"
* location = Reference(SenaiteLocation-001)

// --- Example 2: Biochemistry analyser ---
Instance: SenaiteDevice-002
InstanceOf: SenaiteDevice
Title: "Device: Roche Cobas c502 Biochemistry Analyser"
Description: "Automated biochemistry analyser producing LFT and other chemistry results."
* identifier.system = "http://senaite.example.org/device-id"
* identifier.value = "DEV-002"
* status = #active
* displayName = "Roche Cobas c502"
* manufacturer = "Roche Diagnostics"
* modelNumber = "cobas c 502"
* serialNumber = "ROCHE-C502-20240202"
* location = Reference(SenaiteLocation-002)

// --- Example 3: Urinalysis analyser ---
Instance: SenaiteDevice-003
InstanceOf: SenaiteDevice
Title: "Device: Sysmex UF-5000 Urinalysis Analyser"
Description: "Automated urinalysis analyser processing urine specimens."
* identifier.system = "http://senaite.example.org/device-id"
* identifier.value = "DEV-003"
* status = #active
* displayName = "Sysmex UF-5000"
* manufacturer = "Sysmex Corporation"
* modelNumber = "UF-5000"
* serialNumber = "SYS-UF-20240303"
* location = Reference(SenaiteLocation-003)
