// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteOrganization-examples.fsh                                │
// ╰──────────────────────────────────────────────────────────────────╯

// --- Example 1: General hospital ---
Instance: SenaiteOrganization-001
InstanceOf: SenaiteOrganization
Title: "Organization: City General Hospital"
Description: "A general hospital that submits lab requests to SENAITE."
* identifier.system = "http://senaite.example.org/organization-id"
* identifier.value = "ORG-001"
* name = "City General Hospital"
* contact.telecom.system = #phone
* contact.telecom.value = "+61 2 9000 0001"
* contact.address.line = "1 Hospital Drive"
* contact.address.city = "Sydney"
* contact.address.state = "NSW"
* contact.address.postalCode = "2000"

// --- Example 2: Specialist clinic ---
Instance: SenaiteOrganization-002
InstanceOf: SenaiteOrganization
Title: "Organization: Northside Haematology Clinic"
Description: "A specialist haematology clinic ordering complex panels."
* identifier.system = "http://senaite.example.org/organization-id"
* identifier.value = "ORG-002"
* name = "Northside Haematology Clinic"
* contact.telecom.system = #phone
* contact.telecom.value = "+61 2 9000 0002"

// --- Example 3: GP practice (no identifier) ---
Instance: SenaiteOrganization-003
InstanceOf: SenaiteOrganization
Title: "Organization: Westfield Family Practice"
Description: "A general practice clinic — identifier not yet registered in SENAITE."
* name = "Westfield Family Practice"
* contact.telecom.system = #email
* contact.telecom.value = "admin@westfieldfp.example.org"
