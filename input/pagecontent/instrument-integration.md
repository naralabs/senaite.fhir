# Instrument Integration

This workflow describes a **FHIR R5 native instrument integration pattern** where the
Instrument Middleware acts as the translation layer between the instrument's proprietary
protocol and FHIR. The middleware polls for work via FHIR ServiceRequests and pushes
results back as individual FHIR Observations — one POST per result. This workflow feeds
directly into the Request/Results Workflow once results are published.

## Artefacts for Instrument Workflow
See:
- [Profiles](artifacts.html): these define the structure of particular resources as they vary from the base type.
- [Instances or Examples](artifacts.html): these are examples of each of the profiles above. Available in JSON or XML.

## Device Registration

Before the instrument workflow can begin, each laboratory instrument must be manually
registered in SENAITE by a lab administrator via the instrument management interface.
This is the source of truth for device records — SENAITE owns the instrument registry,
not the middleware.

Once registered, the middleware performs a one-time GET at startup to confirm the device
exists and retrieve its logical ID:

```
GET {fhir_api_root}/Device?identifier=<asset_number>
```

If the device is found, the middleware caches the returned `Device/{id}` and includes it
in the `Observation.device` reference on every subsequent result POST. If the device is
not found, the middleware should halt and alert the administrator — results must not be
pushed without a valid device reference, as SENAITE will be unable to attribute results
to the correct instrument for QC and audit purposes.

> **Note:** `Observation.device` is optional at the profile level to allow the profile to
> serve both the request/results and instrument workflows. For the instrument workflow,
> populating `device` is expected on every Observation.

<div align="center">
  <img src="seq-device-registration.png" alt="Device registration sequence diagram" class="image-centered" />
</div>

## Sequence Diagram & Explanation

<div align="center">
  <img src="seq-instrument.png" alt="Instrument integration workflow sequence diagram" class="image-centered" />
</div>

1. **Pre-condition — sample reception (SENAITE internal):** Before the instrument integration workflow begins, the sample has already been received by the lab and worksheets have been assigned internally within SENAITE. This is the trigger point for the instrument integration to commence.

2. **Worklist fetch (Instrument Middleware → SENAITE FHIR API):** The Instrument Middleware polls the SENAITE FHIR API for active lab requests using a FHIR R5 GET against the ServiceRequest endpoint, filtered by `status=active` and `_lastUpdated=<since>` to only retrieve new or changed requests since the last poll. The FHIR API responds with a Bundle containing the matching ServiceRequests.

3. **Worklist transmission (Instrument Middleware → Laboratory Instrument):** The Instrument Middleware translates the FHIR ServiceRequests into the instrument's native format (e.g. HL7, ASTM or proprietary) and transmits the worklist to the Laboratory Instrument. This translation layer is a key responsibility of the middleware but its details are out of scope for this IG.

4. **Instrument processing (Laboratory Instrument — internal):** Shown as a parallel block, this step happens independently and asynchronously. The technician loads the samples onto the instrument and runs the analyses. Multiple results are generated per ServiceRequest as the instrument completes its processing — for example a full blood count ServiceRequest would generate individual results for haemoglobin, white cell count, platelets and so on.

5. **Results transmission (Laboratory Instrument → Instrument Middleware):** Once analyses are complete, the Laboratory Instrument transmits the raw results back to the Instrument Middleware in its native format (HL7, ASTM or proprietary). The middleware is responsible for receiving and interpreting these results.

6. **Results push (Instrument Middleware → SENAITE FHIR API):** The middleware translates each raw instrument result into a FHIR Observation and POSTs it individually to `{fhir_api_root}/Observation`. Each Observation references the originating ServiceRequest via `Observation.basedOn` — allowing SENAITE to match the result to the correct lab request — and references the instrument via `Observation.device`. Results are posted as they arrive from the instrument rather than buffered until all analyses are complete.

7. **Result validation (SENAITE FHIR API → SENAITE Application — internal):** The FHIR API maps each incoming Observation to its matching analysis within SENAITE. The application then auto-verifies results against configured reference ranges, flagging any that fall outside acceptable limits for further review.

8. **Manual review — if required (SENAITE Application — internal):** Where results have been flagged outside reference ranges, a lab scientist reviews and manually verifies them before they are accepted. This step is conditional and only occurs when auto-verification has not passed.

9. **Publication (SENAITE Application — internal):** Once all results have been verified — either automatically or manually — SENAITE publishes the DiagnosticReport, grouping all associated Observations via `DiagnosticReport.result`. This makes the results available for retrieval via the FHIR API by the External Consumer as described in the Request/Results Workflow.