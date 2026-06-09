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

REPORT_STATUSES = {
    "sample_received": "preliminary",
    "to_be_verified": "preliminary",
    "published": "final",
    "invalid": "entered-in-error",
    "rejected": "cancelled",
    "cancelled": "cancelled",
    "retracted": "entered-in-error",
    "dispatched": "final",
}

ANALYSIS_REPORTABLE_STATUSES = (
    "to_be_verified",
    "verified",
    "published",
)
