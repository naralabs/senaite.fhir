# -*- coding: utf-8 -*-

FHIR_BASE_URL = "https://fhir.senaite.org"
FHIR_STORAGE_KEY = "senaite.fhir.storage"

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
    ("sample_received", "preliminary"),
    ("to_be_verified", "preliminary"),
    ("published", "final"),
    ("invalid", "entered-in-error"),
    ("rejected", "cancelled"),
    ("cancelled", "cancelled"),
    ("retracted", "entered-in-error"),
    ("dispatched", "final"),
    # Default status if no match
    (None, )
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
