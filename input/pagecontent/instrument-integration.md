# Instrument Integration

This workflow describes a **FHIR R5 native instrument integration pattern** where the 
Instrument Middleware acts as the translation layer between the instrument's proprietary 
protocol and FHIR. The middleware polls for work via FHIR ServiceRequests and pushes 
results back as a FHIR Transaction Bundle of Observations — one Bundle per ServiceRequest, 
containing multiple Observations. This ensures atomic delivery of results and keeps the 
entire integration above the middleware layer purely FHIR R5 based. This workflow feeds 
directly into the Request/Results Workflow once results are published.

<div align="center">
  <img src="seq-instrument.png" alt="Example workflow of request/results exchange" class="image-centered" />
</div>

### 1. Pre-condition: Sample Reception (SENAITE Application — internal)

Before the instrument integration workflow begins, the sample has already been received 
by the lab and worksheets have been assigned internally within SENAITE. This is the 
trigger point for the instrument integration to commence.

---

### 2. Worklist Fetch (Instrument Middleware → SENAITE FHIR API)

The Instrument Middleware polls the SENAITE FHIR API for active lab requests using a 
FHIR R5 GET request against the ServiceRequest endpoint, filtered by `status=active` 
and `_lastUpdated=<since>` to only retrieve new or changed requests since the last poll. 
The FHIR API responds with a Bundle containing the matching ServiceRequests.

---

### 3. Worklist Transmission (Instrument Middleware → Laboratory Instrument)

The Instrument Middleware translates the FHIR ServiceRequests into the instrument's 
native format (e.g. HL7, ASTM or proprietary) and transmits the worklist to the 
Laboratory Instrument. This translation layer is a key responsibility of the middleware but its details are out of scope for this IG.

---

### 4. Instrument Processing (Laboratory Instrument — internal)

This is shown as a parallel block, indicating it happens independently and asynchronously. 
The technician loads the samples onto the instrument and runs the analyses. Multiple 
results are generated per ServiceRequest as the instrument completes its processing — 
for example a full blood count ServiceRequest would generate individual results for 
haemoglobin, white cell count, platelets and so on.

---

### 5. Results Transmission (Laboratory Instrument → Instrument Middleware)

Once analyses are complete, the Laboratory Instrument transmits the raw results back to 
the Instrument Middleware in its native format (HL7, ASTM or proprietary). The middleware 
is responsible for receiving and interpreting these results.

---

### 6. Results Push (Instrument Middleware → SENAITE FHIR API)

The Middleware translates the raw instrument results into FHIR Observations and POSTs 
them as a FHIR Transaction Bundle to `{fhir_api_root}/Bundle`. Each Observation 
references the originating ServiceRequest via `Observation.basedOn`, allowing SENAITE 
to correctly match results to the original lab request. Posting as a Transaction Bundle 
ensures all Observations for a ServiceRequest are received and processed atomically — 
either all succeed or all fail together.

---

### 7. Result Validation (SENAITE FHIR API → SENAITE Application — internal)

The FHIR API maps the incoming Observation Bundle to their matching analyses within 
SENAITE. The application then auto-verifies the results against configured reference 
ranges, flagging any results that fall outside acceptable limits for further review.

---

### 8. Manual Review — if required (SENAITE Application — internal)

Where results have been flagged outside reference ranges, a lab scientist reviews and 
manually verifies the results before they are accepted. This step is conditional and 
only occurs when auto-verification has not passed.

---

### 9. Publication (SENAITE Application — internal)

Once all results have been verified — either automatically or manually — SENAITE publishes 
the DiagnosticReport, grouping all associated Observations via `DiagnosticReport.result`. 
This makes the results available for retrieval via the FHIR API by the External Consumer 
as described in the Request/Results Workflow.
