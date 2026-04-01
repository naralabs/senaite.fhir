
### Workflow-first approach

Integrations with SENAITE are best initially considered in terms of workflows. Workflows avoid becoming mired in technical domain language too early, require almost no tech literacy and focus on what flows goes where. Also if a manual (paper-based) workflow exists, the automated version can mirror it and hence its digital equivalent is quickly comprehensible by lab staff with no experience in API design.

The two main workflows for SENAITE are:
- **Lab request and results**: Lab requests are sent to SENAITE's FHIR API in the form of a Bundle that includes all relevant resources including:
  - ServiceRequest: Details of the lab request.
  - Patient: The subject of the Service Request.
  - Specimen: The specimen that will be tested.
  - Encounter: Details in which the test was ordered.
  - Practitioner: The medical officer that ordered the test.
- **Instrument Integration**: This is the standardised workflow by which instruments are able to send results to SENAITE via the FHIR API. 

### SENAITE is the API Provider
<div class="info-box">
A note on flow direction: The following workflows identified below assume the SENAITE is the API provider. This is the strongly recommended choice. The alternative choice is the user implements their own API based on these specs. Our experience has shown this is slower and more error-prone.
</div>

### Workflows
#### Workflow 1: Lab Results

This is what most people would consider the main workflow in a LIMS integration: posting lab requests to SENAITE and fetching results back to the consumer whether an EHR or middleware layer.

This workflow handles the following cases:

1. **Lab Test Ordered:** *A new lab test has been ordered in the external system and the details need to be shared with SENAITE for processing*. This will include details about the sample/specimen along with test information like profiles/panels and tests.
2. **Lab Test Updated/Cancelled:** *The details of an ordered lab test changes and needs to be shared with SENAITE*. Sometimes this means a lab test has been cancelled (updating the test's status cancelled). Complexities lie in how far along the processing pipeline that test can be cancelled.
3. **Report Available:** *Once testing is complete the results of a test is to be shared by SENAITE to an external system.* Due to complexities around structuring the vast array of possible test results across multiple categories - this report can be a PDF as published from SENAITE. Additionally, the quantitative results can be represented in a structured form for parsing by the external software. This work still needs to be done.

<div align="center">
  <img src="seq-req-res.png" alt="Example workflow of request/results exchange" class="image-centered" />
</div>


##### Sequence Diagram Explanation: Request/Results Workflow
The diagram describes a **request-in, poll-for-results** integration pattern, where the consumer 
pushes a lab order, waits for the lab to process it, and then retrieves results either as structured 
FHIR data or as a PDF report.

###### 1. Pushing the Request (External Consumer → SENAITE FHIR API)

The workflow begins with the External Consumer (e.g. a hospital system or ordering application) 
POSTing a FHIR Transaction Bundle to the SENAITE FHIR API. This bundle contains all the resources 
needed to create a lab request, including the ServiceRequest, Patient, Specimen, Encounter, and 
Practitioner, with Location and Organization being optional.

---

###### 2. Internal Processing (SENAITE FHIR API → SENAITE Application)

Once received, the FHIR API processes the Bundle and instructs the SENAITE Application to generate 
a new Sample — translating the FHIR resources into SENAITE's internal data model.

---

###### 3. Acknowledgement (SENAITE FHIR API → External Consumer)

The FHIR API returns a FHIR Transaction Response Bundle back to the External Consumer, confirming 
that the request was received and processed successfully.

---

###### 4. Sample Processing (SENAITE Application — internal)

This is shown as a parallel block, indicating it happens independently and asynchronously. A lab 
clerk works through the sample processing workflow inside SENAITE — receiving, analysing, and 
resulting the sample.

---

###### 5. Results Polling (External Consumer → SENAITE FHIR API)

Once the consumer is ready to check for results, it polls the FHIR API using a GET request filtered 
by `_lastUpdated` (to only fetch new/changed results), with `_summary=true` and 
`_include=Observations`. The API responds with a Bundle containing the DiagnosticReport and 
associated Observations.

---

###### 6. PDF Report Fetch (External Consumer → SENAITE FHIR API)

Finally, the consumer can retrieve the full PDF report by fetching a specific DiagnosticReport by 
its UID. The API responds with the DiagnosticReport resource containing the full PDF encoded as a 
base64 attachment.

#### Workflow 2: Instrument Integration
<div align="center">
  <img src="seq-instrument.png" alt="Example workflow of request/results exchange" class="image-centered" />
</div>

This workflow describes a **FHIR R5 native instrument integration pattern** where the 
Instrument Middleware acts as the translation layer between the instrument's proprietary 
protocol and FHIR. The middleware polls for work via FHIR ServiceRequests and pushes 
results back as a FHIR Transaction Bundle of Observations — one Bundle per ServiceRequest, 
containing multiple Observations. This ensures atomic delivery of results and keeps the 
entire integration above the middleware layer purely FHIR R5 based. This workflow feeds 
directly into the Request/Results Workflow once results are published.

###### 1. Pre-condition: Sample Reception (SENAITE Application — internal)

Before the instrument integration workflow begins, the sample has already been received 
by the lab and worksheets have been assigned internally within SENAITE. This is the 
trigger point for the instrument integration to commence.

---

###### 2. Worklist Fetch (Instrument Middleware → SENAITE FHIR API)

The Instrument Middleware polls the SENAITE FHIR API for active lab requests using a 
FHIR R5 GET request against the ServiceRequest endpoint, filtered by `status=active` 
and `_lastUpdated=<since>` to only retrieve new or changed requests since the last poll. 
The FHIR API responds with a Bundle containing the matching ServiceRequests.

---

###### 3. Worklist Transmission (Instrument Middleware → Laboratory Instrument)

The Instrument Middleware translates the FHIR ServiceRequests into the instrument's 
native format (e.g. HL7, ASTM or proprietary) and transmits the worklist to the 
Laboratory Instrument. This translation layer is a key responsibility of the middleware.

---

###### 4. Instrument Processing (Laboratory Instrument — internal)

This is shown as a parallel block, indicating it happens independently and asynchronously. 
The technician loads the samples onto the instrument and runs the analyses. Multiple 
results are generated per ServiceRequest as the instrument completes its processing — 
for example a full blood count ServiceRequest would generate individual results for 
haemoglobin, white cell count, platelets and so on.

---

###### 5. Results Transmission (Laboratory Instrument → Instrument Middleware)

Once analyses are complete, the Laboratory Instrument transmits the raw results back to 
the Instrument Middleware in its native format (HL7, ASTM or proprietary). The middleware 
is responsible for receiving and interpreting these results.

---

###### 6. Results Push (Instrument Middleware → SENAITE FHIR API)

The Middleware translates the raw instrument results into FHIR Observations and POSTs 
them as a FHIR Transaction Bundle to `{fhir_api_root}/Bundle`. Each Observation 
references the originating ServiceRequest via `Observation.basedOn`, allowing SENAITE 
to correctly match results to the original lab request. Posting as a Transaction Bundle 
ensures all Observations for a ServiceRequest are received and processed atomically — 
either all succeed or all fail together.

---

###### 7. Result Validation (SENAITE FHIR API → SENAITE Application — internal)

The FHIR API maps the incoming Observation Bundle to their matching analyses within 
SENAITE. The application then auto-verifies the results against configured reference 
ranges, flagging any results that fall outside acceptable limits for further review.

---

###### 8. Manual Review — if required (SENAITE Application — internal)

Where results have been flagged outside reference ranges, a lab scientist reviews and 
manually verifies the results before they are accepted. This step is conditional and 
only occurs when auto-verification has not passed.

---

###### 9. Publication (SENAITE Application — internal)

Once all results have been verified — either automatically or manually — SENAITE publishes 
the DiagnosticReport, grouping all associated Observations via `DiagnosticReport.result`. 
This makes the results available for retrieval via the FHIR API by the External Consumer 
as described in the Request/Results Workflow.
