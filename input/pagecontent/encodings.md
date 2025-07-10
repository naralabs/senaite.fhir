# Encodings

Whereas FHIR refers to the syntax (structuring) of data, encodings are required to define the semantics or what things mean. In order to remove ambiguity its important to have codesets that will uniquely identify important things like tests. The following encodings are usually required to be agreed between systems:

## Patient

Depending on which fields are used encodings are sometimes needed for Patient details like language or country (address).

## Request definition

- Individual test code: how to identify the individual test. Previously we have used [LOINC codes](https://loinc.org/) here.
- Profile/panel code: How to identify a test code. Again in the past this has been done with LOINC.
- Category: Defining the type of service request. Used [SNOMED](https://hl7.org/fhir/valueset-servicerequest-category.html) in the past.

Other encodings relate to how resources are processed between systems for example:
- [ServiceRequest.status](https://hl7.org/fhir/servicerequest-definitions.html#ServiceRequest.status)\*: This is used to encode what stage the service request has progressed to in processing. It is **required** meaning that this type is mandatory.
- [ServiceRequest.priority](https://hl7.org/fhir/servicerequest-definitions.html#ServiceRequest.priority)\*: The priority of the request.

\* For these FHIR mandates a specific encoding.

## Specimen

- Specimen type: [can use this HL7 format but also there is a limited mapping to SNOMED too.](https://terminology.hl7.org/5.1.0/ValueSet-v2-0487.html)