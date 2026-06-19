# -*- coding: utf-8 -*-

FHIR_BASE_URL = "https://fhir.senaite.org"
FHIR_STORAGE_KEY = "senaite.fhir.storage"

# Mapping of FHIR resource type -> SENAITE portal type for objects that carry
# a separate FHIR resource ID (e.g. Patient, Specimen, etc.)
FHIR_RESOURCE_TO_PORTAL_TYPE = (
    ("Patient", "Patient"),
    ("Organization", "Client"),
    ("Practitioner", "Contact"),
    ("Observation", "Analysis"),
    ("DiagnosticReport", "ResultsReport"),
    ("Specimen", "SampleType"),
    ("ServiceRequest", "AnalysisRequest"),
)

SYSTEM_CODES = (
    ("AnalysisProfile", "http://loinc.org"),
    ("AnalysisService", "http://loinc.org"),
    ("Specimen", "http://snomed.info/sct"),
    ("SamplePoint", "http://snomed.info/sct"),
)

UCUM_SYSTEM = "http://unitsofmeasure.org"

SERVICE_REQUEST_STATUSES = (
    # mapping between Sample status and ServiceRequest's FHIR statuses
    # FHIR ValueSet: draft | active | on-hold | revoked | completed |
    #                entered-in-error | unknown
    # https://hl7.org/fhir/R5/valueset-request-status.html
    ("sample_received", "active"),
    ("to_be_verified", "active"),
    ("published", "completed"),
    ("invalid", "entered-in-error"),
    ("rejected", "revoked"),
    ("cancelled", "revoked"),
    ("retracted", "entered-in-error"),
    ("dispatched", "completed"),
    # Default status if no match
    (None, "active")
)

DIAGNOSTIC_REPORT_STATUSES = (
    # mapping between Sample status and DiagnosticReport's FHIR statuses
    # IMPORTANT: Note that SENAITE relies on Sample's status instead of the
    #            status of the ResultsReport!
    # FHIR ValueSet: registered | partial | preliminary | modified | final |
    #                amended | corrected | appended | cancelled |
    #                entered-in-error | unknown
    # https://hl7.org/fhir/R5/valueset-diagnostic-report-status.html
    ("sample_registered", None),
    ("scheduled_sampling", None),
    ("to_be_sampled", None),
    ("sample_due", None),
    ("sample_received", "preliminary"),
    ("to_be_verified", "preliminary"),
    ("to_be_preserved", None),
    ("verified", "preliminary"),
    ("published", "final"),
    ("rejected", "cancelled"),
    ("invalid", "entered-in-error"),
    ("cancelled", "cancelled"),
    ("dispatched", None),
    # Default status if no match
    (None, "registered"),
)

OBSERVATION_STATUSES = (
    # mapping between Analysis status and Observation's FHIR statuses
    # FHIR ValueSet: registered | preliminary | final | amended | corrected |
    #                cancelled | entered-in-error | unknown
    # https://hl7.org/fhir/R5/valueset-observation-status.html
    ("registered", "registered"),
    ("unassigned", "registered"),
    ("assigned", "registered"),
    ("cancelled", "cancelled"),
    ("to_be_verified", "registered"),
    ("retracted", "entered-in-error"),
    ("rejected", "cancelled"),
    ("verified", "preliminary"),
    ("published", "final"),
    # Default status if no match
    (None, "registered")
)

ANALYSIS_REPORTABLE_STATUSES = (
    # Analyses that are in this status will be reported as Observations
    "to_be_verified",
    "verified",
    "published",
)

DEFAULT_REPORT_PROFILE_CODE = {
    # TODO Make the default DiagnosticReport code configurable in setup
    # Default DiagnosticReport code for when the number of profiles/panels
    # assigned to a sample are different from 1
    "text": "Relevant diagnostic tests/laboratory data note",
    "coding": [{
        "code": "30954-2",
        "system": "http://loinc.org",
        "display": "Relevant diagnostic tests/laboratory data note"
      }]
}
