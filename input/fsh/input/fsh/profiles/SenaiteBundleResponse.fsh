Invariant:  relative-ref
Description: "fullUrl in a transaction-response must be a relative ResourceType/id reference"
Expression: "matches('^[A-Z][a-zA-Z]+/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')"
Severity:   #error

// ============================================================
// SenaiteBundleResponse
// ============================================================
Profile:     SenaiteBundleResponse
Parent:      Bundle
Id:          SenaiteBundleResponse
Title:       "Senaite Bundle Response"
Description: """The transaction-response Bundle returned by the server after successfully
processing a SenaiteBundle. One entry is returned per entry in the request,
in the same order. Each entry carries the server-assigned fullUrl and a
response status. No resource body or request element is included."""
* ^status = #draft

// Bundle-level constraints
* id        1..1
* type      = #transaction-response (exactly)
* entry     1..*

// Suppress elements not used in a response Bundle
* identifier ..0
* total      ..0
* link       ..0
* signature  ..0

// ---------------------------------------------------------------
// Entry-level constraints — applied to all entries globally.
// Slicing by resource type is not possible here since no resource
// body is returned; cardinality of entries mirrors SenaiteBundle.
// ---------------------------------------------------------------

// fullUrl is required and must be ResourceType/{uuid} style
* entry.fullUrl 1..1
* entry.fullUrl obeys relative-ref

// No resource body or search in a transaction-response
* entry.resource ..0
* entry.search   ..0

// request is not echoed back in a response Bundle
* entry.request  ..0

// response is required for every entry
* entry.response                  1..1
* entry.response.status           1..1
* entry.response.lastModified     1..1

// location and etag are optional — servers may omit them
* entry.response.location         ..0
* entry.response.etag             ..0
* entry.response.outcome          ..0
