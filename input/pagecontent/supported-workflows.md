
### Workflow-first approach

Integrations with SENAITE are best initially considered in terms of workflows. Workflows avoid becoming mired in technical domain language too early, require almost no tech literacy and focus on what flows goes where. Also if a manual (paper-based) workflow exists, the automated version can mirror it and hence its digital equivalent is quickly comprehensible by lab staff with no experience in API design.

The two main workflows for SENAITE are:
- **Lab request and results**: Lab requests are sent to SENAITE's FHIR API in the form of a self-contained Bundle that includes all relevant resources including:
  - ServiceRequest: Details of the lab request, including the panel or profile requested and the individual tests.
  - Patient: The subject of the Service Request.
  - Specimen: The specimen that will be tested.
  - Encounter: Details in which the test was ordered.
  - Practitioner: The medical officer that ordered the test.
- **Instrument Integration**: This is the standardised workflow by which instruments are able to send results to SENAITE via the FHIR API. 

### SENAITE is the API Provider
<div class="info-box">
A note on flow direction: The following workflows identified below assume SENAITE is the API provider. This is the strongly recommended choice. The alternative choice is the user implements their own API based on these specs. Our experience has shown this is slower and more error-prone.
</div>

### Workflows
The supported workflows are split into dedicated pages:

- [Lab Request and Results](lab-request-and-results.html)
- [Instrument Integration](instrument-integration.html)

Use the links above to view each workflow in detail.
