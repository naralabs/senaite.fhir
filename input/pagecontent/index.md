
<div align="center">
  <img src="senaite_product_logo.png" alt="Senaite Logo" class="image-centered" />
</div>

# Introduction
The purpose of this Implementation Guide is to explain the process of integrating [SENAITE LIMS](https://www.senaite.com/) into a digital human or animal health ecosystem using the standard Fast Health Interoperability Resources (FHIR) version R5.

Should your use cases reside outside of health such as industrial applications please contact [Naralabs](mailto:info@naralabs.com) for assistance.

For those unfamiliar, FHIR uses a RESTFul API approach based on data structures called Resources. Full FHIR documentation is available [here](https://hl7.org/fhir/R5/index.html).

## Target Audience
The likely user of this IG is a party wishing integrate SENAITE into a wider health eco-system, most likely either directly with an EHR or with a Middleware layer as part of a broader interoperability strategy. The workflows listed below enable external requests for sample processing to be available in SENAITE and results created for those requests from SENAITE to be made available EHR. Please see the Design Principles section below to understand the options regarding the flow of these resources.

Another audience might be those who wish to integrate intruments with SENAITE via a FHIR protocol.  

## Design Principles
To expose lab requests and attain their results from SENAITE the first decision should be to decide on which side is hosting the API. There are two options here:
1. (**Strongly Recommended**) *Use SENAITE's FHIR API*: Here SENAITE is the API provider. All lab requests will be sent to SENAITE's API (in the form of ServiceRequests) and results are fetched from SENAITE. This has multiple advantages including:
    - Use SENAITE's sample API environment: This can be used to understand how these specifications work in real life using sample data.
    - Decoupling the organizations development: meeting for an initial explanation session and again for end-to-end testing.
2. (**Supported but not recommended**) *You provide the API based on these specs*: Here the results are fetched by SENAITE from your API and the results are PUSH'ed to you.
   - This is usually a slow implementation process because regardless of documentation implementing another's specifications often is a slow and, in our experience error-prone process.
   - Each round of testing requires the involvment of both parties which also slows this down.

# Quick Start (Under Construction)
> Note the testing API is still a work-in-progress. This section will be usable once the API has been released. For updates please email info@naralabs.com.

Follow the following **Quick Start** process:
1. Request access to test API from info@naralabs.com. You will be provided with auth details.
2. Fetch test patients by running:
`GET https://[baseUrl]/patients`

