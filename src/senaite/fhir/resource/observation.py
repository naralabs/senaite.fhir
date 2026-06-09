# -*- coding: utf-8 -*-

from senaite.fhir.datatype.codeableconcept import CodeableConcept
from senaite.fhir.datatype.reference import Reference
from senaite.fhir.interfaces import IObservationResource
from senaite.fhir.resource import FHIRResource
from zope.interface import implementer


@implementer(IObservationResource)
class ObservationResource(FHIRResource):
    """FHIR Observation resource representing a single analyte result.
    https://fhir.senaite.org/StructureDefinition-SenaiteObservation.html
    """

    __cardinality = (
        ("id", "1..1"),
        ("status", "1..1"),
        ("code", "1..1"),
    )

    @property
    def basedOn(self):
        """Reference to the originating ServiceRequest.
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.basedOn
        """
        data = self.get("basedOn") or []
        return [Reference(item) for item in data]

    @property
    def status(self):
        """The status of the result value.
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.status
        """
        return self.get("status")

    @property
    def code(self):
        """Type of observation (LOINC or local code).
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.code
        """
        element = self.get("code")
        return CodeableConcept(element) if element else None

    @property
    def performer(self):
        """Who performed the observation (analyst).
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.performer
        """
        return self.get("performer") or []

    @property
    def valueQuantity(self):
        """Numeric result with unit.
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.value_x_
        """
        return self.get("valueQuantity")

    @property
    def valueString(self):
        """Non-numeric result as plain text.
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.value_x_
        """
        return self.get("valueString")

    @property
    def referenceRange(self):
        """Normal range for this observation.
        https://www.hl7.org/fhir/R5/observation-definitions.html#Observation.referenceRange
        """
        return self.get("referenceRange") or []
