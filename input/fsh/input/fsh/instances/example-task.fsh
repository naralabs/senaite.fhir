Instance: example-task
InstanceOf: SenaiteTask
Title: "[Task] CBC Instrument Task"
Description: "Task representing the instrument worklist item for the CBC order."
Usage: #example
* id = "task-cbc-001"
* identifier.system = "http://hospital.senaite.com/tasks"
* identifier.value = "TASK-CBC-001"
* status = #accepted
* intent = #order
* focus.reference = "ServiceRequest/example-servicerequest"
* for.reference = "Patient/example-patient"
* owner.reference = "Device/example-device"
* output[0].type.text = "Observation result"
* output[0].valueReference.reference = "Observation/instrument-obs-hb"