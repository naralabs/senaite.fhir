Profile: SenaiteObservation
Parent: Observation
Id: SenaiteObservation
Description: """A single quantitative result produced by an instrument and pushed to SENAITE or made available within a SenaiteDiagnosticReport bundle.
- `code` (LOINC) identifies the specific analyte, matched against ServiceRequest.orderDetail codes.
- `basedOn` links the result back to the originating ServiceRequest.
- `device` optionally identifies the instrument that produced the result."""
* ^status = #draft
* extension ..0
* modifierExtension ..0
* identifier ..0
// Optional — identifies the instrument that produced this result.
// basedOn block for instrument results — links Observation to its ServiceRequest
* device 0..1
* device only Reference(SenaiteDevice)
* device.reference 1..
* device.type ..0
* device.identifier ..0
* device.display ..0

* partOf ..0
* category ..0
* subject ..0
* focus ..0
* encounter ..0
* effective[x] ..0
* issued ..0
* performer ..0
* dataAbsentReason ..0
* interpretation ..0
* bodySite ..0
* method ..0
* specimen ..0
* referenceRange ..0
* hasMember ..0
* derivedFrom ..0
* component ..0