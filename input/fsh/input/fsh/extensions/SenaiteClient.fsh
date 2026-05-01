// ============================================================
// Extension: SenaiteClient
// Context:   SenaiteServiceRequest (ServiceRequest)
//
// Purpose:
//   In a LIMS context, a "Client" is the organisation that
//   submits samples and receives results. FHIR's Encounter
//   (a clinical patient-clinician interaction) is not a natural
//   fit for this relationship. This extension lets a
//   ServiceRequest carry a direct, typed reference to the
//   submitting Organisation without needing an Encounter as
//   an intermediate bridge.
// ============================================================

Extension: SenaiteClient
Id: SenaiteClient
Title: "SENAITE Client"
Description: """
  The Organisation (Client) that submits the laboratory request
  and to whom results will be reported. This replaces the need
  for an Encounter reference to convey organisational origin
  in a LIMS workflow.
"""
Context: ServiceRequest

* ^version = "0.01"
* ^status = #draft

// Only one client per request
* . 1..1
* . ^short = "The submitting client organisation"
* . ^definition = """
    A direct reference to the Organisation that is placing this
    laboratory request. In SENAITE this maps to the Client
    registered in the LIMS. If the client is not yet known, it
    will be created on receipt.
  """

// The extension carries a single Reference value
* value[x] only Reference(SenaiteOrganization)
* value[x] 1..1
* value[x] ^short = "Reference to the SenaiteOrganization (Client)"
* value[x] ^definition = """
    Must resolve to a SenaiteOrganization resource. The
    Organisation name and identifier are used by SENAITE to
    match or create the corresponding Client record.
  """