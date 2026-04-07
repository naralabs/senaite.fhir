Instance: example-organization
InstanceOf: SenaiteOrganization
Title: "[Organization] Microbiology Laboratory"
Description: "Organization resource representing the Microbiology laboratory including contact details and address."
Usage: #example
* id = "micro-lab"
* active = true
* name = "Microbiology Lab"
* identifier.system = "http://hospital.com/departments/lab"
* identifier.value = "microbio"
* contact[0].telecom[0].system = #email
* contact[0].telecom[0].value = "micro@hospital.com"
* contact[0].telecom[1].system = #phone
* contact[0].telecom[1].value = "+61 7777 8883"
* contact[0].address.line[0] = "The Alfred Hospital"
* contact[0].address.line[1] = "55 Commercial Rd"
* contact[0].address.postalCode = "3004"
* contact[0].address.city = "Melbourne"
* contact[0].address.state = "Victoria"