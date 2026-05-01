// ============================================================
// Aliases
// ============================================================
Alias: $loinc        = http://loinc.org
Alias: $sct          = http://snomed.info/sct
Alias: $obsValue     = http://terminology.hl7.org/CodeSystem/v3-ObservationValue


// ============================================================
// Patient – James Nguyen
// ============================================================
Instance:   JamesNguyen
InstanceOf: SenaitePatient
Usage:      #inline
* identifier[0].value = "MRN-20394857"
* name[0].family      = "Nguyen"
* name[0].given[0]    = "James"
* gender              = #male
* birthDate           = "1985-09-14"


// ============================================================
// Organization – Royal Melbourne Hospital (Client)
// Required bundle entry; referenced by the ServiceRequest
// via extension[SenaiteClient].
// ============================================================
Instance:   RoyalMelbourneHospital
InstanceOf: SenaiteOrganization
Usage:      #inline
* identifier[0].value = "ORG-RMH-MEL"
* name                = "Royal Melbourne Hospital"


// ============================================================
// Practitioner – Dr. Catherine Sullivan
// ============================================================
Instance:   DrCatherineSullivan
InstanceOf: SenaitePractitioner
Usage:      #inline
* identifier[0].value = "PRACT-DR-SULLIVAN"
* name[0].family      = "Sullivan"
* name[0].given[0]    = "Catherine"
* name[0].prefix[0]   = "Dr."


// ============================================================
// Specimen – serum, collected AEST
// ============================================================
Instance:   LiverPanelSerum
InstanceOf: SenaiteSpecimen
Usage:      #inline
* type = $sct#119364003 "Serum specimen"
* collection.collectedDateTime = "2026-04-08T08:30:00+10:00"


// ============================================================
// ServiceRequest – Hepatic Function Panel (LOINC 24325-3)
// ============================================================
Instance:   LiverPanelServiceRequest
InstanceOf: SenaiteServiceRequest
Usage:      #inline

// Client – points at the Organization entry in this bundle
* extension[SenaiteClient].valueReference.reference = "urn:uuid:6c248ba7-a4c4-4606-b4a0-efbff71fb902"

* status = #active
* intent = #order
* category[0] = $sct#108252007 "Laboratory procedure"
* category[0].text = "Laboratory procedure"
* code = $loinc#24325-3 "Hepatic function 2000 panel - Serum or Plasma"

// ALT
* orderDetail[0].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[0].parameter[0].valueCodeableConcept = $loinc#1742-6 "ALT [Enzymatic activity/volume] in Serum or Plasma"
// AST
* orderDetail[1].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[1].parameter[0].valueCodeableConcept = $loinc#1920-8 "AST [Enzymatic activity/volume] in Serum or Plasma"
// ALP
* orderDetail[2].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[2].parameter[0].valueCodeableConcept = $loinc#6768-6 "Alkaline phosphatase [Enzymatic activity/volume] in Serum or Plasma"
// Total Bilirubin
* orderDetail[3].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[3].parameter[0].valueCodeableConcept = $loinc#1975-2 "Bilirubin.total [Mass/volume] in Serum or Plasma"
// Direct Bilirubin
* orderDetail[4].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[4].parameter[0].valueCodeableConcept = $loinc#1968-7 "Bilirubin.direct [Mass/volume] in Serum or Plasma"
// Total Protein
* orderDetail[5].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[5].parameter[0].valueCodeableConcept = $loinc#2885-2 "Protein [Mass/volume] in Serum or Plasma"
// Albumin
* orderDetail[6].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[6].parameter[0].valueCodeableConcept = $loinc#1751-7 "Albumin [Mass/volume] in Serum or Plasma"
// Prothrombin Time
* orderDetail[7].parameter[0].code                 = $obsValue#LOINC "Test Code"
* orderDetail[7].parameter[0].valueCodeableConcept = $loinc#5902-2 "Prothrombin time (PT)"

* subject        = Reference(JamesNguyen)
* requester.type = "Practitioner"
* requester      = Reference(DrCatherineSullivan)
* specimen[0]    = Reference(LiverPanelSerum)


// ============================================================
// Transaction Bundle
// ============================================================
Instance:   LiverPanelTransactionBundle
InstanceOf: SenaiteRequestBundle
Title: "[Bundle] Liver Panel Transaction Bundle"
Description: """
  Transaction bundle for a liver panel order. Contains Patient,
  Organization (Client), Practitioner, Specimen, and ServiceRequest.
  The submitting Client is identified via extension[SenaiteClient]
  on the ServiceRequest, pointing at the Organization entry.
"""
Usage: #example
* type = #transaction

* entry[patient].fullUrl              = "urn:uuid:ddaf107d-a44d-4b7b-966b-65d82de495cc"
* entry[patient].resource             = JamesNguyen
* entry[patient].request.method       = #POST
* entry[patient].request.url          = "Patient"

* entry[organization].fullUrl         = "urn:uuid:6c248ba7-a4c4-4606-b4a0-efbff71fb902"
* entry[organization].resource        = RoyalMelbourneHospital
* entry[organization].request.method  = #POST
* entry[organization].request.url     = "Organization"

* entry[practitioner].fullUrl         = "urn:uuid:ab1ecb26-1942-4855-a32d-ee82c62e5327"
* entry[practitioner].resource        = DrCatherineSullivan
* entry[practitioner].request.method  = #POST
* entry[practitioner].request.url     = "Practitioner"

* entry[specimen].fullUrl             = "urn:uuid:9b8a478f-fd26-4765-8f09-3b3ea0ec6637"
* entry[specimen].resource            = LiverPanelSerum
* entry[specimen].request.method      = #POST
* entry[specimen].request.url         = "Specimen"

* entry[serviceRequest].fullUrl          = "urn:uuid:2d6bb491-6b87-4558-a07f-2d181831e298"
* entry[serviceRequest].resource         = LiverPanelServiceRequest
* entry[serviceRequest].request.method   = #POST
* entry[serviceRequest].request.url      = "ServiceRequest"
