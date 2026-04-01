// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteEncounter.fsh                                            │
// │  Encounter that triggered the ServiceRequest                    │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteEncounter
Parent: Encounter
Id: SenaiteEncounter
Title: "SENAITE Encounter"
Description: "The Encounter which triggered the SenaiteServiceRequest. Captures the location and service provider that ordered the test."
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Status ---
* status 1..1 MS
* status = #completed (exactly)
* status ^short = "completed — only finished encounters are accepted"
* status ^definition = "Only completed encounters are accepted by SENAITE."

// --- Class (R5: class replaces class with CodeableConcept) ---
* class 1..1 MS
* class ^short = "Classification of the encounter e.g. inpatient, outpatient"
* class.coding 1..1 MS
* class.coding.system from $v3-ActEncounterCode-vs (preferred)

// --- Location ---
* location 1..1 MS
* location ^short = "The location where the encounter took place — used to route results"
* location.extension 0..0
* location.modifierExtension 0..0
* location.location 1..1 MS
* location.location only Reference(SenaiteLocation)
* location.location ^definition = "The location where the encounter takes place. Used to determine where to send results. If SENAITE does not recognise the location it will be created."
* location.location.extension 0..0
* location.form 0..1 MS
* location.form.coding 1..1 MS
* location.form.coding.system = "http://terminology.hl7.org/CodeSystem/location-physical-type" (exactly)
* location.form.coding.version 0..0

// --- Service Provider ---
* serviceProvider 0..1 MS
* serviceProvider only Reference(SenaiteOrganization)
* serviceProvider ^short = "The organization responsible for the encounter"
* serviceProvider.extension 0..0
* serviceProvider.type = "Organization" (exactly)
* serviceProvider.identifier 0..0

// --- Zero out unused elements ---
* extension 0..0
* modifierExtension 0..0
* identifier 0..0
// statusHistory does not exist in R5 — removed
* type 0..0
* serviceType 0..0
* priority 0..0
* subject 0..0
* subjectStatus 0..0
* episodeOfCare 0..0
* basedOn 0..0
* careTeam 0..0
* partOf 0..0
* serviceProvider 0..1
* participant 0..0
* appointment 0..0
* virtualService 0..0
* actualPeriod 0..0
* plannedStartDate 0..0
* plannedEndDate 0..0
* length 0..0
* reason 0..0
* diagnosis 0..0
* account 0..0
* dietPreference 0..0
* specialArrangement 0..0
* specialCourtesy 0..0
* admission 0..0
