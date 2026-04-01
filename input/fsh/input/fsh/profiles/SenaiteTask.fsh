// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteTask.fsh                                                 │
// │  Tracks instrument workflow lifecycle for a ServiceRequest       │
// ╰──────────────────────────────────────────────────────────────────╯

Profile: SenaiteTask
Parent: Task
Id: SenaiteTask
Description: """Tracks the lifecycle of a lab test as it progresses through instrument
processing. Updated by the middleware as the instrument works through the sample.

Lifecycle: requested → accepted → in-progress → completed | failed"""
* ^status = #draft

// --- Status ---
* status 1..
* status from SenaiteTaskStatusVS (required)
* status ^short = "requested | accepted | in-progress | completed | failed"

// --- Intent ---
* intent = #order (exactly)

// --- Timestamps ---
* authoredOn 1..
* authoredOn ^short = "When the task was created by SENAITE"
* lastModified 1..
* lastModified ^short = "When the middleware last updated the task status"

// --- Links to other resources ---
* focus 1..
* focus only Reference(SenaiteServiceRequest)
* focus ^short = "The ServiceRequest this task is fulfilling"
* focus.reference 1..
* focus.identifier ..0
* focus.display ..0

* for 1..
* for only Reference(SenaitePatient)
* for ^short = "The patient"
* for.reference 1..
* for.identifier ..0
* for.display ..0

* owner 1..
* owner only Reference(SenaiteDevice)
* owner ^short = "The instrument assigned to process this sample"
* owner.reference 1..
* owner.identifier ..0
* owner.display ..0

// --- Business status (optional - for middleware-specific state) ---
* businessStatus ^short = "Optional middleware-specific sub-status (e.g. 'queued', 'running')"
* businessStatus.coding.system 1..
* businessStatus.coding.code 1..

// --- Strip unused elements ---
* extension ..0
* modifierExtension ..0
* identifier ..0
* instantiatesCanonical ..0
* instantiatesUri ..0
* basedOn ..0
* groupIdentifier ..0
* partOf ..0
* statusReason ..0
* code ..0
* description ..0
* executionPeriod ..0
* requester ..0
* performerType ..0
* reason ..0
* insurance ..0
* note ..0
* relevantHistory ..0
* restriction ..0
* input ..0
* output ..0
