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
* telecom[0].system = #email
* telecom[0].value = "micro@hospital.com"
* telecom[1].system = #phone
* telecom[1].value = "+61 7777 8883"
* address[0].line[0] = "The Alfred Hospital"
* address[0].line[1] = "55 Commercial Rd"
* address[0].postalCode = "3004"
* address[0].city = "Melbourne"
* address[0].state = "Victoria"