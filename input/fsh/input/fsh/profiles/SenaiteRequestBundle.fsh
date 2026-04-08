Alias: $senaite = https://senaite-fhir.naralabs.com/en/StructureDefinition

Invariant:  urn-uuid
Description: "fullUrl must be a urn:uuid: reference for POST transaction entries"
Expression: "matches('^urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')"
Severity:   #error

// ============================================================
// SenaiteBundle
// ============================================================
Profile:     SenaiteBundle
Parent:      Bundle
Id:          SenaiteBundle
Title:       "Senaite Bundle"
Description: """A transaction Bundle used to submit a laboratory service request to SENAITE.
The ServiceRequest is the backbone of the Bundle. All referenced resources
(Patient, Encounter, Practitioner, Location, Organization, Specimen) must be
included as entries so the server can resolve intra-Bundle references.
Resource instances may not yet exist on the server; entries use POST so the
server creates them and assigns logical IDs."""
* ^status = #draft

// Bundle-level constraints
* id 1..1
* type  = #transaction (exactly)
* entry 1..*

// Suppress elements not used in this integration
* identifier   ..0
* timestamp    ..0
* total        ..0
* link         ..0
* signature    ..0

// ---------------------------------------------------------------
// Entry slice definitions
// One required slice per resource type; all use POST.
// ---------------------------------------------------------------
* entry ^slicing.discriminator.type = #profile
* entry ^slicing.discriminator.path = "resource"
* entry ^slicing.rules             = #open
* entry ^slicing.description       = "Sliced by the profile of the contained resource"

* entry contains
    serviceRequest 1..1 and
    patient        1..1 and
    encounter      1..1 and
    practitioner   1..1 and
    specimen       1..1 and
    organization   0..1 and
    location       0..1

// ---------------------------------------------------------------
// ServiceRequest entry
// ---------------------------------------------------------------
* entry[serviceRequest].fullUrl  1..1
* entry[serviceRequest].fullUrl obeys urn-uuid
* entry[serviceRequest].resource 1..1
* entry[serviceRequest].resource only SenaiteServiceRequest
* entry[serviceRequest].search   ..0
* entry[serviceRequest].response ..0
* entry[serviceRequest].request  1..1
* entry[serviceRequest].request.method = #POST (exactly)
* entry[serviceRequest].request.url    = "ServiceRequest" (exactly)

// ---------------------------------------------------------------
// Patient entry
// ---------------------------------------------------------------
* entry[patient].fullUrl  1..1
* entry[patient].fullUrl obeys urn-uuid
* entry[patient].resource 1..1
* entry[patient].resource only SenaitePatient
* entry[patient].search   ..0
* entry[patient].response ..0
* entry[patient].request  1..1
* entry[patient].request.method = #POST (exactly)
* entry[patient].request.url    = "Patient" (exactly)

// ---------------------------------------------------------------
// Encounter entry
// ---------------------------------------------------------------
* entry[encounter].fullUrl  1..1
* entry[encounter].fullUrl obeys urn-uuid
* entry[encounter].resource 1..1
* entry[encounter].resource only SenaiteEncounter
* entry[encounter].search   ..0
* entry[encounter].response ..0
* entry[encounter].request  1..1
* entry[encounter].request.method = #POST (exactly)
* entry[encounter].request.url    = "Encounter" (exactly)

// ---------------------------------------------------------------
// Practitioner entry
// ---------------------------------------------------------------
* entry[practitioner].fullUrl  1..1
* entry[practitioner].fullUrl obeys urn-uuid
* entry[practitioner].resource 1..1
* entry[practitioner].resource only SenaitePractitioner
* entry[practitioner].search   ..0
* entry[practitioner].response ..0
* entry[practitioner].request  1..1
* entry[practitioner].request.method = #POST (exactly)
* entry[practitioner].request.url    = "Practitioner" (exactly)

// ---------------------------------------------------------------
// Specimen entry
// ---------------------------------------------------------------
* entry[specimen].fullUrl  1..1
* entry[specimen].fullUrl obeys urn-uuid
* entry[specimen].resource 1..1
* entry[specimen].resource only SenaiteSpecimen
* entry[specimen].search   ..0
* entry[specimen].response ..0
* entry[specimen].request  1..1
* entry[specimen].request.method = #POST (exactly)
* entry[specimen].request.url    = "Specimen" (exactly)

// ---------------------------------------------------------------
// Organization entry (optional — included when the ordering
// organisation is not yet known to the server)
// ---------------------------------------------------------------
* entry[organization].fullUrl  1..1
* entry[organization].fullUrl obeys urn-uuid
* entry[organization].resource 1..1
* entry[organization].resource only SenaiteOrganization
* entry[organization].search   ..0
* entry[organization].response ..0
* entry[organization].request  1..1
* entry[organization].request.method = #POST (exactly)
* entry[organization].request.url    = "Organization" (exactly)

// ---------------------------------------------------------------
// Location entry (optional — included when the location is not
// yet known to the server)
// ---------------------------------------------------------------
* entry[location].fullUrl  1..1
* entry[location].fullUrl obeys urn-uuid
* entry[location].resource 1..1
* entry[location].resource only SenaiteLocation
* entry[location].search   ..0
* entry[location].response ..0
* entry[location].request  1..1
* entry[location].request.method = #POST (exactly)
* entry[location].request.url    = "Location" (exactly)
