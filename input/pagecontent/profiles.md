# {{page-title}}
The two typical workflows identified above would use the following resources:

- [Patient](https://simplifier.net/senaite-data-modelling/senaitepatient): This resource is used for patient details. In this context it means the subject of the test. A create and update can both use the Patient resource. It is incumbent on SENAITE based on whether the identifier exists to determine whether it is a new patient or an update to an existing patient.
- [Practitioner](https://simplifier.net/senaite-data-modelling/senaitepractitioner): The doctor ordering the tests and the lab staff processing the tests are practitioners.
- [ServiceRequest](https://simplifier.net/senaite-data-modelling/senaiteservicerequest): This contains data about the test being ordered. As with patients the same flow can be used for create and update, but simply checking the existence of a id.
  - [Specimen](https://simplifier.net/senaite-data-modelling/senaitespecimen): Data about the sample.
  - [Encounter](https://simplifier.net/senaite-data-modelling/senaiteencounter): Often needed to include data about the context in which the sample was ordered. For example, where to send the result back to, which department ordered the test, where the patient attended the test etc.
  - [Location](https://simplifier.net/senaite-data-modelling/senaitelocation): This is the department that ordered the test.
  - [Organization](https://simplifier.net/senaite-data-modelling/senaiteorganization): Information about the organization which requested the lab test. This is needed to ensure contact between the lab and requesting organization is possible. It could be a referrer, institution, clinic or client.
- [DiagnosticReport](https://simplifier.net/senaite-data-modelling/senaitediagnosticreport): The results of the test take the form of a diagnostic report. Special mention to `DiagnosticReport.presentedForm` [which can include a PDF](https://hl7.org/fhir/diagnosticreport-definitions.html#DiagnosticReport.presentedForm) of the results. Also `DiagnosticReport.basedOn` includes a reference to the original ServiceRequest in order to connect the test and results.
- \[optional\] [Bundle](https://hl7.org/fhir/bundle.html) + [Observation](https://simplifier.net/senaite-data-modelling/senaiteobservation): Should raw data need to be included in the results for parsing, then each value would take the form of an Observation and be grouped together using the Bundle.

**Getting related records**

For the Lab Request workflow - ServiceRequest acts as the central resource but SENAITE needs data from related resources. This can be done in two ways:

1. Using the `_include=` to fetch all resources in the beginning - for example `/ServiceRequest?last_updated=gt<since>&_include=Specimen:specimen&_include=Practitioner:requester&_include=Encounter:encounter` 
2. Alternatively the related fields can be fetched based on the id - so if `ServiceRequest.encounter = Encounter/9de57907-7008-41e1-b47e-693ed7257cee` then we would fetch GET ..`Encounter/9de57907-7008-41e1-b47e-693ed7257cee`

Option 2 is preferred and well supported.

| Resource     | Relation In ServiceRequest | Values Required                                                     | Also supports                                                                                                                 |
|--------------|----------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| [Encounter](https://simplifier.net/senaite-data-modelling/senaiteencounter)    | `ServiceRequest.encounter`   | `encounter.location`  where the sample was collected                  | `encounter.class`<br />`encounter.status`<br />`encounter.subject` (redundant as it needs to be the same as ServiceRequest.subject) |
| [Specimen](https://simplifier.net/senaite-data-modelling/senaitespecimen)     | `ServiceRequest.specimen[0]` | `Specimen.type` (See [here](https://terminology.hl7.org/5.1.0/ValueSet-v2-0487.html))<br />`Specimen.collection.collectedDateTime` | `Specimen.bodySite` (see [here](https://hl7.org/fhir/R5/valueset-body-site.html))<br />`Specimen.collection.collector` (link to pracitioner)                                         |
| [Practitioner](https://simplifier.net/senaite-data-modelling/senaitepractitioner) | `ServiceRequest.requester`   | `Practitioner.name[0].display`<br />`Practitioner.id`                   |                                                                                                                               |
| Location     | `Encounter[0].location`      | Site specific - we will need to discuss                             |                                                                                                                               |
## Inclusion

Please note that not all these resources will be stand-alone. Some like Specimen will almost always be included within a parent service request. This can be performed in a single fetch using the `_include` parameter, which relies on Resources being related to one another. For example - the ServiceRequest has a [subject](https://hl7.org/fhir/servicerequest-definitions.html#ServiceRequest.subject) of Resource type Patient which is how it relates to the patient. Details [here](https://hl7.org/fhir/R5/search.html#_revinclude).
