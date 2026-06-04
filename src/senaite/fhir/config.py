# -*- coding: utf-8 -*-

FHIR_BASE_URL = "https://fhir.senaite.org"
FHIR_STORAGE_KEY = "senaite.fhir.storage"

SYSTEM_CODES = (
    ("AnalysisProfile", "http://loinc.org"),
    ("AnalysisService", "http://loinc.org"),
    ("Specimen", "http://snomed.info/sct"),
    ("SamplePoint", "http://snomed.info/sct"),
)

REPORT_STATUSES = {
    "sample_received": "partial",
    "to_be_verified": "preliminary",
    "published": "final",
    "invalid": "entered-in-error",
    "rejected": "revoked",
    "cancelled": "revoked",
}
