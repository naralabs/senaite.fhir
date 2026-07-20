# -*- coding: utf-8 -*-
from bika.lims.interfaces import IAnalysis
from DateTime import DateTime
from senaite.fhir import api as fapi
from senaite.fhir.converter import to_fhir_datetime
from senaite.fhir.resource import FHIRResource


def setInstrument(self, value, **kwargs):
    """Sets the assigned Instrument and links (or refreshes) a FHIR
    SenaiteInstrumentServiceRequest to/on the Analysis. Monkey-patched
    because plain AT field mutators don't fire any event on their own, and
    Instrument gets assigned from several places (worksheet bulk actions,
    AJAX endpoints, edit forms) that don't consistently notify one either.
    """
    self.getField("Instrument").set(self, value, **kwargs)

    if IAnalysis.providedBy(self):
        link_instrument_service_request(self)


def link_instrument_service_request(analysis):
    """Links a FHIR SenaiteInstrumentServiceRequest to the given Analysis,
    provided it has an Instrument assigned; skips it otherwise.

    If a ServiceRequest (intent=filler-order) is already linked, its
    ``authoredOn`` is refreshed instead of minting a new identity. The uid
    is distinct from the Analysis' own SENAITE uid, so this resource keeps
    a stable identity of its own, separate from the Analysis' default
    Observation representation.

    :param analysis: the Analysis to link a SenaiteInstrumentServiceRequest
        uid to
    :returns: the FHIR uid (hex), or ``None`` when no Instrument is assigned
    """
    if not analysis.getRawInstrument():
        return None

    now = to_fhir_datetime(DateTime())
    uid = fapi.get_fhir_uid(analysis, "ServiceRequest")
    storage = fapi.get_fhir_storage(analysis)
    data = storage.get("data")
    if uid and data and data.get("intent") == "filler-order":
        # refresh authoredOn on the existing ServiceRequest
        data["authoredOn"] = now
        storage["data"] = data
        return uid

    uid = fapi.generate_UUID().hex
    resource = FHIRResource({
        "resourceType": "ServiceRequest",
        "id": str(fapi.get_uuid(uid)),
        "intent": "filler-order",
        "authoredOn": now,
    })
    fapi.link_fhir_resource(analysis, resource)
    return uid
