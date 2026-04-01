// ╭──────────────────────────────────────────────────────────────────╮
// │  SenaiteTaskStatusVS.fsh                                         │
// │  Constrained ValueSet for Task status in instrument workflows    │
// ╰──────────────────────────────────────────────────────────────────╯

ValueSet: SenaiteTaskStatusVS
Id: SenaiteTaskStatusVS
Title: "SENAITE Task Status Value Set"
Description: "Permitted Task status values for instrument workflow tracking in SENAITE."
* ^status = #draft
* ^version = "1.0.0"

* $task-status#requested    "Requested"
* $task-status#accepted     "Accepted"
* $task-status#in-progress  "In Progress"
* $task-status#completed    "Completed"
* $task-status#failed       "Failed"
