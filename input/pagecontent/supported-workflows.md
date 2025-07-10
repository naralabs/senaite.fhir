# Supported Workflows

## Workflow-driven

Integrations with SENAITE are best initially considered in terms of workflows. Workflows avoid becoming mired in technical domain language too early, require almost no tech literacy and focus on what flows where. Also if a manual (paper-based) workflow exists, the automated version can mirror it and hence it is comprehensible by lab staff with no experience in API design.

The two supported workflows for SENAITE are:

- **Patient Synchronization**: Ensuring patient details are up-to-date in SENAITE. Often a patient's demographic data will influence the results these need to be made up to date.
- **Lab request and results**: Ensuring requests for lab tests are fetched by SENAITE with results sent from SENAITE to the external software.

::: info
These two workflows can be collapsed into a single workflow where the patient details are included in a Bundle with the other Lab Request Resources. The reasons for them being treated distinctly was to open up the possibility of manual tests being created in SENAITE and needing up-to-date patient data.    
:::

## SENAITE is the Consumer

It is worth noting that while stipulating profiles, SENAITE does not as yet have a FHIR API, although this will change soon. As such SENAITE is always the consumer - fetching lab requests, patient updated data and posting results. This is reflected in the SENAITE add-on details [here](https://github.com/naralabs/senaite.fhir.api).

# Workflows
## Workflow 1: Patient Synchronization

Ensures that patient demographic data is kept up-to-date for results processing, a patient synchronization workflow consisting of two use-cases is implemented. 

The two use-cases are: 

1. **New Patient Created:** *A new patient has been created in the external system and the patient's demographics will be fetched by SENAITE.*
2. **Patient update:** *The external system updates patient data* and because tests require up-to-date demographics this change needs to be communicated. This can include notification that the patient is deceased or can even feature in more complex workflows like patient merges.

![Sequence Diagram: Patient Synchronization between SENAITE and an EHR](seq-patient-sync.png)

::: info
Note: this workflow is *unidirectional* so post-deployment patient editing will be turned-off within SENAITE. The external consumer will be considered the source of truth. 
:::

Both use cases will adapt the synchronization workflow described in search for the case of Observations [here](https://hl7.org/fhir/R4B/search.html#all). The request will be:

`GET {base_url}/Patient?_lastUpdated=gt<since>`

where:

- `gt` is the logical operator for greater-than.
- `since` is the [dateTime](https://hl7.org/fhir/R4B/datatypes.html#dateTime) of the latest last modified patient *last fetched*. This ensures that all time management is handled according to the API Server rather than the client. 

::: info
For example, if the fetch returned a Bundle with 20 patients with one patient's `meta.lastUpdated` being `2025-07-07T13:28:17.239+01:00` with the other 19 being older, since would become `2025-07-07T13:28:17.239+01:00` for the subsequent request. 

:::

This polling request will return patients that need to be conformant to the SENAITEPatient profile which inherits from Patient. See *Resources* section. 

## Workflow 2: Lab Results

This is what most people would consider the main workflow in a LIMS integration: getting Lab requests into SENAITE and returning results back to the original EHR.

This workflow handles the following cases:

1. **Lab Test Ordered:** *A new lab test has been ordered in the external system and the details need to be shared with SENAITE for processing*. This will include details about the sample/specimen along with test information like profiles/panels and tests.
2. **Lab Test Updated/Cancelled:** *The details of an ordered lab test changes and needs to be shared with SENAITE*. Sometimes this means a lab test has been cancelled (updating the test's status cancelled). Complexities lie in how far along the processing pipeline that test can be cancelled.
3. **Report Available:** *Once testing is complete the results of a test is to be shared by SENAITE to an external system.* Due to complexities around structuring the vast array of possible test results across multiple categories - this report can be a PDF as published from SENAITE. Additionally, the quantitative results can be represented in a structured form for parsing by the external software. This work still needs to be done.

![Example workflow of request/results exchange](seq-req-res.png)

New requests are handled with:  
`GET {base_url}/ServiceRequest?_lastUpdated=gt<since>`

The same logic for `since` as in the Patient workflow is used here, where since is determined by the latest serviceRequest from the last successful fetch.  