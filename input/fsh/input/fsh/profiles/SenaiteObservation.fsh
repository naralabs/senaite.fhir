Profile: SenaiteObservation
Parent: Observation
Id: SenaiteObservation
Description: "A single quantitative result produced by an instrument and pushed to SENAITE. basedOn links the result back to the originating ServiceRequest."
* ^status = #draft
* extension ..0
* modifierExtension ..0
* identifier ..0

// basedOn block for instrument results — links Observation to its ServiceRequest
* basedOn 0..1
* basedOn only Reference(SenaiteServiceRequest)
* basedOn.reference 1..
* basedOn.type ..0
* basedOn.identifier ..0
* basedOn.display ..0

// Optional — identifies the instrument that produced this result.
// Allows SENAITE to track results per device for QC and audit purposes.
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
* device ..0
* referenceRange ..0
* hasMember ..0
* derivedFrom ..0
* component ..0