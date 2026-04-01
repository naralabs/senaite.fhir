// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaitePatient-examples.fsh                                     │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: Standard adult patient ---
Instance: SenaitePatient-001
InstanceOf: SenaitePatient
Title: "Patient: James Nguyen"
Description: "Standard adult male patient with a known date of birth."
* identifier.system = "http://senaite.example.org/patient-id"
* identifier.value = "PAT-001"
* name.family = "Nguyen"
* name.given = "James"
* gender = #male
* birthDate = "1978-04-22"

// --- Example 2: Female patient with estimated date of birth ---
Instance: SenaitePatient-002
InstanceOf: SenaitePatient
Title: "Patient: Maria Santos (estimated DOB)"
Description: "Adult female patient whose date of birth is an estimate."
* extension[estimatedDateBirth].valueBoolean = true
* identifier.system = "http://senaite.example.org/patient-id"
* identifier.value = "PAT-002"
* name.family = "Santos"
* name.given = "Maria"
* gender = #female
* birthDate = "1965-01-01"

// --- Example 3: Deceased patient ---
Instance: SenaitePatient-003
InstanceOf: SenaitePatient
Title: "Patient: Robert Okafor (deceased)"
Description: "Male patient with a recorded date of death."
* identifier.system = "http://senaite.example.org/patient-id"
* identifier.value = "PAT-003"
* name.family = "Okafor"
* name.given = "Robert"
* gender = #male
* birthDate = "1942-11-03"
* deceasedDateTime = "2024-08-15T10:30:00Z"
