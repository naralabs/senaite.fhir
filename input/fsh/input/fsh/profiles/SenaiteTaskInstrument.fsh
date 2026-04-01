// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteTaskInstrument.fsh                                       │
// │  Extension to reference the instrument Device on a Task         │
// ╰──────────────────────────────────────────────────────────────────╯

Extension: SenaiteTaskInstrument
Id: SenaiteTaskInstrument
Title: "SENAITE Task Instrument"
Description: """References the laboratory instrument (Device) responsible for executing
this Task. Used because R5 Task.performer.actor and Task.owner do not permit
Device references — this extension bridges that gap."""
* ^status = #draft
* ^version = "1.0.0"
* ^context[+].type = #element
* ^context[=].expression = "Task"

* value[x] only Reference(SenaiteDevice)
* value[x] 1..1 MS
* value[x] ^short = "The instrument Device responsible for executing this Task"
