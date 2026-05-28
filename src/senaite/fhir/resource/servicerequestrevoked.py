# -*- coding: utf-8 -*-

from senaite.fhir.interfaces import IServiceRequestResource
from senaite.fhir.resource.operationoutcome import FHIRResource
from senaite.fhir.resource.operationoutcome import OperationOutcome
from senaite.fhir.resource.servicerequest import ServiceRequestResource
from zope.interface import implementer


@implementer(IServiceRequestResource)
class ServiceRequestRevokedResource(ServiceRequestResource):
    """The ServiceRequest resource returned by the server in the
    200 OK response body after a successful $revoke operation.
    Identical to SenaiteServiceRequest but with status fixed to revoked,
    meta.versionId and meta.lastUpdated required to confirm the update
    was applied, and note optionally populated with the plain-text reason
    supplied to the $revoke operation.
    https://fhir.senaite.org/StructureDefinition-SenaiteServiceRequestRevoked.html
    """
    __cardinality = (
        ("note", "0..*"),
    )

    __fixed_values = (
        ("status", "revoked"),
    )

    @property
    def note(self):
        """Text carries the reason supplied in the $revoke call.
        """
        return self.get("note")


@implementer(IServiceRequestResource)
class ServiceRequestRevocationError(FHIRResource):
    """The OperationOutcome returned with a 409 Conflict when a
    ServiceRequest cannot be revoked, for example because results have
    already been published in SENAITE.
    https://fhir.senaite.org/StructureDefinition-SenaiteServiceRequestRevocationError.html
    """
    __cardinality = (
        ("issue", "1..1"),
    )

    @property
    def issue(self):
        """Captures issues and warnings that relate to the construction of the
        Bundle and the content within it.
        https://fhir.senaite.org/StructureDefinition-SenaiteServiceRequestRevocationError.html#ServiceRequest.issues
        """
        record = self.get("issue") or {}
        return OperationOutcome(record)
