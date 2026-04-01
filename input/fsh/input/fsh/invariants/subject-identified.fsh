// ╭──────────────────────────────────────────────────────────────────╮
// │  subject-identified.fsh                                          │
// │  Invariant ensuring subject is identifiable                     │
// ╰──────────────────────────────────────────────────────────────────╯

Invariant: subject-identified
Description: "Subject must be identifiable — either a resolvable reference or a reference with a business identifier."
* severity = #error
* expression = "reference.exists() or identifier.exists()"
