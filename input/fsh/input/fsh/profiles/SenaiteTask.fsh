// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteTask.fsh                                                 │
// │  Tracks instrument workflow lifecycle for a ServiceRequest      │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteTask
Parent: Task
Id: SenaiteTask
Title: "SENAITE Instrument Task"
Description: """Tracks the lifecycle of a worklist item dispatched to a laboratory instrument.
Created when the middleware fetches a ServiceRequest and dispatched to the instrument.
Updated as the instrument progresses through the workflow."""
* ^status = #draft
* ^version = "1.0.0"
* ^fhirVersion = #5.0.0

// --- Identifier ---
* identifier 1..* MS
* identifier ^short = "Unique identifier for the task"

// --- Status ---
* status 1..1 MS
* status from SenaiteTaskStatusVS (required)
* status ^short = "requested | accepted | in-progress | completed | failed"

// --- Intent ---
* intent 1..1 MS
* intent = #order (exactly)

// --- Focus (the ServiceRequest being fulfilled) ---
* focus 1..1 MS
* focus only Reference(SenaiteServiceRequest)
* focus ^short = "The ServiceRequest this task is fulfilling"
* focus.reference 1..1 MS
* focus.identifier 0..0
* focus.display 0..0

// --- For (the patient) ---
* for 1..1 MS
* for only Reference(SenaitePatient)
* for ^short = "The patient the task relates to"
* for.reference 1..1 MS
* for.identifier 0..0
* for.display 0..0

// --- Instrument Device (via extension) ---
// R5 Task.performer.actor and Task.owner do not support Device references.
// The instrument is referenced via a custom extension instead.
* extension contains SenaiteTaskInstrument named instrument 1..1 MS
* extension[instrument] ^short = "The instrument Device responsible for executing this Task"

// --- Zero out performer entirely ---
* performer 0..0

// --- Execution Period ---
* executionPeriod 0..1 MS
* executionPeriod ^short = "When the task was started and completed on the instrument"

// --- Output (references to produced Observations) ---
* output 0..* MS
* output ^short = "References to Observations produced by this task"
* output.type 1..1 MS
* output.value[x] only Reference(SenaiteInstrumentObservation)

// --- Zero out unused elements ---
* modifierExtension 0..0
* instantiatesCanonical 0..0
* instantiatesUri 0..0
* basedOn 0..0
* groupIdentifier 0..0
* partOf 0..0
* statusReason 0..0
* businessStatus 0..0
* doNotPerform 0..0
* requestedPeriod 0..0
* location 0..0
* reason 0..0
* insurance 0..0
* note 0..0
* relevantHistory 0..0
* restriction 0..0
* input 0..0
* requester 0..0
