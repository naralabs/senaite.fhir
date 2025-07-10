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
The Repository uses [FHIR ShortHand (FSH)](https://build.fhir.org/ig/HL7/fhir-shorthand/) using the [SUSHI](https://github.com/FHIR/sushi) but it still contains all the FSH details on:


- **profiles** (See: `input/fsh/input/fsh/profiles`)  
  Custom FHIR profiles for resources like `Patient`, `ServiceRequest`, `DiagnosticReport`, etc.

- **examples** (See: `input/fsh/input/fsh/instances`)  
  Sample FHIR resource payloads for typical SENAITE workflows.

### Documentation
The MD files that are converted into the SENAITE Implementation Guide are available: `input/pagecontent`
They include:
- **[Workflows](input/pagecontent/supported-workflows.md)**
  Sequence diagrams and documentation outlining supported integration workflows.

- **[Project Management](input/pagecontent/project-management.md)**  
  Mappings between SENAITE internal data models and FHIR resources.

## 🚀 Getting Started
### Prerequisites
- Need the latest java runtime installed
- Jekyll Installed
- Sushi installed as described [here](https://github.com/FHIR/sushi?tab=readme-ov-file#installation-for-sushi-users)
### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/senaite-fhir.git
2. Set up the Implementation Guide Publisher
    ```bash
    ./_updatePublisher.sh
3. Generate the Implementation Guide
    ```bash
    ./_genonce.sh
If you then navigate to the output: `output/index.html` this is the implementation guide.