# -*- coding: utf-8 -*-

from bika.lims import api
from senaite.fhir.converter import to_fhir_profile_url
from senaite.fhir.datatype.meta import Meta
from senaite.fhir.interfaces import IFHIRResource
from senaite.fhir.interfaces import IServiceRequestResource
from senaite.fhir.resource import FHIRResource
from senaite.fhir.resource.operationoutcome import OperationOutcome
from senaite.fhir.resource.servicerequest import ServiceRequestResource
from zope.interface import implementer


@implementer(IFHIRResource)
class ServiceRequestRevocationResource(FHIRResource):
    """FHIR Parameters payload for ServiceRequest $revoke.
    """
    __fixed_values = (
        ("resourceType", "Parameters"),
    )

    @property
    def parameter(self):
        parameters = self.get("parameter") or []
        return parameters if api.is_list(parameters) else [parameters]

    @property
    def rejection_reason(self):
        """Maps FHIR Parameters.reason values to SENAITE rejection reasons.
        """
        selected = []
        other = []
        available_reasons = self.get_available_reasons()

        for param in self.parameter:
            if not isinstance(param, dict):
                continue
            if param.get("name") != "reason":
                continue

            reason = api.safe_unicode(param.get("valueString")).strip()
            if not reason:
                continue

            matched = None
            for available_reason in available_reasons:
                available_reason_text = api.safe_unicode(available_reason).strip()  # noqa: E501
                if available_reason_text.lower() == reason.lower():
                    matched = available_reason
                    break

            if matched:
                if matched not in selected:
                    selected.append(matched)
            elif reason not in other:
                other.append(reason)

        if not any([selected, other]):
            return []

        return [{"selected": selected, "other": ", ".join(other)}]

    def get_available_reasons(self):
        setup = api.get_senaite_setup()
        return setup.getRejectionReasons() or []


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
    __fixed_values = (
        ("status", "revoked"),
    )


@implementer(IServiceRequestResource)
class ServiceRequestRevocationError(OperationOutcome):
    """The OperationOutcome returned with a 409 Conflict when a
    ServiceRequest cannot be revoked, for example because results have
    already been published in SENAITE.
    https://fhir.senaite.org/StructureDefinition-SenaiteServiceRequestRevocationError.html
    """
    __cardinality = (
        ("issue", "1..1"),
    )

    def _initialize(self):
        super(ServiceRequestRevocationError, self)._initialize()
        profile = to_fhir_profile_url(self.__class__.__name__)
        self["meta"] = Meta({"profile": [profile]})
