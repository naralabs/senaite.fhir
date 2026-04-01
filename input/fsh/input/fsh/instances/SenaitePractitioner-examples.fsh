// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaitePractitioner-examples.fsh                                │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: General practitioner ---
Instance: SenaitePractitioner-001
InstanceOf: SenaitePractitioner
Title: "Practitioner: Dr. Sarah Mitchell"
Description: "General practitioner ordering a routine full blood count."
* identifier.system = "http://senaite.example.org/provider-number"
* identifier.value = "DR-001"
* name.family = "Mitchell"
* name.given = "Sarah"
* name.prefix = "Dr."

// --- Example 2: Specialist ---
Instance: SenaitePractitioner-002
InstanceOf: SenaitePractitioner
Title: "Practitioner: Dr. Alan Patel"
Description: "Haematology specialist ordering a specialised panel."
* identifier.system = "http://senaite.example.org/provider-number"
* identifier.value = "DR-002"
* name.family = "Patel"
* name.given = "Alan"
* name.prefix = "Dr."

// --- Example 3: Hospital registrar ---
Instance: SenaitePractitioner-003
InstanceOf: SenaitePractitioner
Title: "Practitioner: Dr. Yuki Tanaka"
Description: "Hospital registrar ordering an emergency biochemistry panel."
* identifier.system = "http://senaite.example.org/provider-number"
* identifier.value = "DR-003"
* name.family = "Tanaka"
* name.given = "Yuki"
* name.prefix = "Dr."
