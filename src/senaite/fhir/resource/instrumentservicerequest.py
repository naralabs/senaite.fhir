# -*- coding: utf-8 -*-

from senaite.core.api import dtime
from senaite.fhir.datatype.annotation import Annotation
from senaite.fhir.datatype.codeableconcept import CodeableConcept
from senaite.fhir.datatype.codeablereference import CodeableReference
from senaite.fhir.datatype.identifier import Identifier
from senaite.fhir.datatype.reference import Reference
from senaite.fhir.interfaces import IServiceRequestResource
from senaite.fhir.resource import FHIRResource
from zope.interface import implementer


@implementer(IServiceRequestResource)
class InstrumentServiceRequestResource(FHIRResource):
    """The filler-order ServiceRequest FHIR resource that links the
    Instrument assigned to an Analysis. Its uid is distinct from the
    Analysis' own SENAITE uid, so this resource keeps a stable identity of
    its own, separate from the Analysis' default Observation representation.
    https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest.html
    """
    __fixed_values = (
        ("resourceType", "ServiceRequest"),
        ("intent", "filler-order"),
    )

    @property
    def identifier(self):
        """Identifiers assigned to this instrument service request instance
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.identifier
        """
        data = self.get("identifier") or []
        return [Identifier(item) for item in data]

    @property
    def basedOn(self):
        """Reference to the SenaiteServiceRequest (placer order) this
        instrument service request was derived from
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.basedOn
        """
        data = self.get("basedOn") or []
        return [Reference(item) for item in data]

    @property
    def status(self):
        """The status of the order
        Value set: draft | active | on-hold | revoked | entered-in-error |
                   unknown
        https://hl7.org/fhir/R5/valueset-request-status.html
        """
        return self.get("status")

    @property
    def intent(self):
        """Always "filler-order" for this resource
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.intent
        """
        return self.get("intent")

    @property
    def category(self):
        """This will always be a Laboratory procedure
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.category
        """
        items = self.get("category") or []
        return [CodeableConcept(item) for item in items]

    @property
    def code(self):
        """A code that identifies the analysis service this request refers
        to. The codes SHOULD be taken from http://loinc.org
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.code
        """
        element = self.get("code")
        return CodeableReference(element) if element else None

    @property
    def subject(self):
        """The patient the service is ordered for
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.subject
        """
        element = self.get("subject")
        return Reference(element) if element else None

    @property
    def authoredOn(self):
        """Date/time the Instrument was assigned to the Analysis
        https://hl7.org/fhir/R5/servicerequest-definitions.html#ServiceRequest.authoredOn
        """
        return dtime.to_dt(self.get("authoredOn"))

    @property
    def performer(self):
        """The Device (Instrument) the analysis is assigned to
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.performer
        """
        data = self.get("performer") or []
        return [Reference(item) for item in data]

    @property
    def specimen(self):
        """The specimen the analysis was performed on
        https://fhir.senaite.org/StructureDefinition-SenaiteInstrumentServiceRequest-definitions.html#key_ServiceRequest.specimen
        """
        data = self.get("specimen") or []
        return [Reference(item) for item in data]

    @property
    def note(self):
        """Any other notes and comments made about the instrument service
        request
        https://hl7.org/fhir/R5/servicerequest-definitions.html#ServiceRequest.note
        """
        items = self.get("note") or []
        return [Annotation(item) for item in items]
