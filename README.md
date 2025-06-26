# SENAITE FHIR Profiles and Data Modelling

This repository provides the FHIR implementation guide, data models, and sample workflows for integrating with **[SENAITE](https://www.senaite.com/)** using HL7® FHIR® (Fast Healthcare Interoperability Resources). It is intended for health information system developers, integration specialists, and laboratories wishing to implement standards-based interoperability with SENAITE.

---

## 🔍 Overview

SENAITE is a powerful open-source Laboratory Information Management System (LIMS). This project enables standards-based communication between SENAITE and other health systems using FHIR.

Key integration workflows include:

- 🔄 **Patient Demographics Synchronization**  
  Sync patient records from Electronic Medical Record (EMR) systems to SENAITE using FHIR `Patient` resources.

- 🧪 **Service Request Submission**  
  Send laboratory test orders using the FHIR `ServiceRequest` and `Specimen` resources.

- 📤 **Diagnostic Report Retrieval**  
  Receive results from SENAITE in the form of structured FHIR `DiagnosticReport` and `Observation` resources.

---

## 📦 Repository Contents

- `profiles/`  
  Custom FHIR profiles for resources like `Patient`, `ServiceRequest`, `DiagnosticReport`, etc.

- `examples/`  
  Sample FHIR resource payloads for typical SENAITE workflows.

- `workflows/`  
  Sequence diagrams and documentation outlining supported integration workflows.

- `mappings/`  
  Mappings between SENAITE internal data models and FHIR resources.

- `docs/`  
  Additional documentation, including implementation guidance and API behavior.

---

## 🧭 Integration Workflows

### 1. Patient Demographics

FHIR Resource: [`Patient`](https://hl7.org/fhir/patient.html)

**Direction:** EMR → SENAITE  
SENAITE consumes FHIR `Patient` resources to create or update patient records.

### 2. Lab Test Orders

FHIR Resources:  
- [`ServiceRequest`](https://hl7.org/fhir/servicerequest.html)  
- [`Specimen`](https://hl7.org/fhir/specimen.html)

**Direction:** EMR → SENAITE  
Lab test orders are submitted as `ServiceRequest` resources, linked `Specimen` data.

### 3. Diagnostic Reports

FHIR Resources:  
- [`DiagnosticReport`](https://hl7.org/fhir/diagnosticreport.html)  
- [`Observation`](https://hl7.org/fhir/observation.html)

**Direction:** SENAITE → EMR  
Test results are returned via `DiagnosticReport`, with detailed `Observation` data for each analyte.

---

## 🚀 Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/senaite-fhir.git
