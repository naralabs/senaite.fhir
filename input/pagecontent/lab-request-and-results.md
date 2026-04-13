# Lab Request and Results

This is what most people would consider the main workflow in a LIMS integration: posting lab requests to SENAITE and fetching results back to the consumer whether an EHR or middleware layer.

This workflow handles the following cases:

1. **Lab test ordered:** *A new lab test has been ordered in the external system and the details need to be shared with SENAITE for processing*. This will include details about the sample/specimen along with test information like profiles/panels and tests.
2. **Lab test updated/cancelled:** *The details of an ordered lab test changes and needs to be shared with SENAITE*. Sometimes this means a lab test has been cancelled (updating the test's status to cancelled). Complexities lie in how far along the processing pipeline that test can be cancelled.
3. **Report available:** *Once testing is complete the results of a test are to be shared by SENAITE to an external system.* Due to complexities around structuring the vast array of possible test results across multiple categories, this report can be a PDF as published from SENAITE. Additionally, the quantitative results can be represented in a structured form for parsing by the external software. This work still needs to be done.

## Artefacts for Request/Results Workflow
See:
- [Profiles](artifacts.html#request-results-workflow-—-profiles): these define the structure of particular resources as they vary from the base type.
- [Instances or Examples](artifacts.html#request-results-workflow-—-examples): these are examples of each of the profiles above. Available in JSON or XML.

## Sequence Diagram & Explanation

<div align="center">
  <img src="seq-req-res.png" alt="Example workflow of request/results exchange" class="image-centered" />
</div>

The diagram describes a **request-in, poll-for-results** integration pattern, where the consumer pushes a lab order, waits for the lab to process it, and then retrieves results either as structured FHIR data or as a PDF report.

1. **Pushing the request:** The workflow begins with the External Consumer (e.g. a hospital system or ordering application) POSTing a FHIR Transaction Bundle to the SENAITE FHIR API. This bundle contains all the resources needed to create a lab request, including the ServiceRequest, Patient, Specimen, Encounter, and Practitioner, with Location and Organization being optional. For an example Request Bundle see [here](Bundle-LiverPanelTransactionBundle.json.html).

2. **Internal processing:** Once received, the FHIR API processes the Bundle and instructs the SENAITE Application to generate a new Sample — translating the FHIR resources into SENAITE's internal data model.

3. **Acknowledgement:** The FHIR API returns a FHIR Transaction Response Bundle back to the External Consumer, confirming that the request was received and processed successfully.

4. **Sample processing (SENAITE internal):** Shown as a parallel block, this step happens independently and asynchronously. A lab clerk works through the sample processing workflow inside SENAITE — receiving, analysing, and resulting the sample.

5. **Results polling:** Once the consumer is ready to check for results, it polls the FHIR API using a GET request filtered by `_lastUpdated` (to only fetch new/changed results), with `_summary=true` and `_include=Observations`. The API responds with a Bundle containing the DiagnosticReport and associated Observations.

6. **PDF report fetch:** The consumer can retrieve the full PDF report by fetching a specific DiagnosticReport by its UID. The API responds with the DiagnosticReport resource containing the full PDF encoded as a base64 attachment.

## Secondary Workflow: Revoke Lab Request

<div align="center">
  <img src="seq-revoke-req.png" alt="Revoke lab request sequence diagram" class="image-centered" />
</div>

1. The External Consumer first submits the ServiceRequest Bundle to the SENAITE FHIR API and receives a transaction response bundle.
2. When the lab request must be cancelled, the consumer sends a PATCH to `ServiceRequest/{id}` with a JSON Patch operation of `replace` on `/status` to `revoked`.
3. The SENAITE FHIR API forwards this revoke action to the SENAITE Application, which withdraws the associated sample, updates internal state to `Cancelled`, and notifies downstream systems as needed.
4. The application confirms the revocation and the FHIR API returns `200 OK` with the updated ServiceRequest resource set to `status: revoked` and an incremented `versionId`.

In the diagram, this revoke workflow is effectively a conditional branch from the sample processing stage: the main workflow continues toward result publication, while the revoke workflow terminates the request cleanly and signals the external consumer that the ServiceRequest has been revoked.