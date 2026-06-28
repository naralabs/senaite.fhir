# -*- coding: utf-8 -*-

from bika.lims import api
from bika.lims.interfaces import IAnalysis
from senaite.core.api import dtime
from senaite.fhir import api as fapi
from senaite.fhir.config import OBSERVATION_STATUSES
from senaite.fhir.config import SYSTEM_CODES
from senaite.fhir.config import UCUM_SYSTEM
from senaite.fhir.converter import first_by
from senaite.fhir.converter import to_fhir_profile_url
from senaite.fhir.interfaces import IContentToFHIR
from senaite.fhir.resource.observation import ObservationResource
from zope.component import adapter
from zope.interface import implementer


@adapter(IAnalysis)
@implementer(IContentToFHIR)
class AnalysisToObservation(object):
    """Convert a SENAITE Analysis into a FHIR Observation resource.
    """

    def __init__(self, analysis):
        self.analysis = analysis

    def to_fhir_resource(self):
        profile_url = to_fhir_profile_url("SenaiteObservation")
        data = {
            "resourceType": "Observation",
            "id": str(fapi.get_uuid(self.analysis)),
            "meta": {
                "profile": [profile_url],
                "lastUpdated": self.get_last_updated(),
            },
            "status": self.get_status(),
            "code": self.get_code(),
        }

        based_on = self.get_based_on()
        if based_on:
            data["basedOn"] = based_on

        performer = self.get_performer()
        if performer:
            data["performer"] = performer

        data.update(self.get_value())

        ref_range = self.get_reference_range()
        if ref_range:
            data["referenceRange"] = ref_range

        return ObservationResource(data)

    def get_last_updated(self):
        modified = api.get_modification_date(self.analysis)
        return dtime.to_localized_time(modified, long_format=True)

    def get_status(self):
        status = api.get_review_status(self.analysis)
        mapping = dict(OBSERVATION_STATUSES)
        fhir_status = mapping.get(status)
        if fhir_status:
            return fhir_status
        # return default (None as the key)
        return mapping.get(None)

    def get_sample(self):
        return self.analysis.getRequest()

    def get_source_data(self):
        sample = self.get_sample()
        if not fapi.is_fhir_content(sample):
            return {}
        storage = fapi.get_fhir_storage(sample)
        return storage.get("data") or {}

    def get_code(self):
        ordered_test = self.get_order_detail()
        if ordered_test:
            return ordered_test

        service = self.analysis.getAnalysisService()
        keyword = self.analysis.getKeyword()
        title = api.get_title(self.analysis)
        service_title = api.get_title(service) if service else title
        system = dict(SYSTEM_CODES).get("AnalysisService")
        return {
            "coding": [{
                "system": system,
                "code": keyword,
                "display": service_title,
            }],
            "text": title,
        }

    def get_order_detail(self):
        source_data = self.get_source_data()
        order_details = source_data.get("orderDetail") or []
        system = fapi.get_system_code("AnalysisService")
        keyword = self.analysis.getKeyword()
        title = api.get_title(self.analysis)
        match_by_title = None

        for order_detail in order_details:
            parameters = order_detail.get("parameter") or []
            for param in parameters:
                concept = param.get("valueCodeableConcept") or {}
                coding = first_by(concept.get("coding"), system=system)
                if not coding:
                    continue
                if coding.get("code") == keyword:
                    return concept
                if coding.get("display") == title or concept.get("text") == title:  # noqa: E501
                    match_by_title = concept

        return match_by_title

    def get_based_on(self):
        source_data = self.get_source_data()
        if source_data.get("basedOn"):
            return source_data.get("basedOn")

        sample = self.get_sample()
        if not fapi.is_fhir_content(sample):
            return []

        storage = fapi.get_fhir_storage(sample)
        service_request_uid = storage.get("uids").get("ServiceRequest")
        if not service_request_uid:
            return []

        return [{
            "type": "ServiceRequest",
            "reference": "ServiceRequest/{}".format(
                fapi.get_uuid(service_request_uid)),
        }]

    def get_performer(self):
        verificators = self.analysis.getVerificators()
        userid = verificators[-1] if verificators else None
        if not userid:
            return []
        display = api.get_user_fullname(userid) or userid
        return [{
            "identifier": {"value": userid},
            "display": display,
        }]

    def get_value(self):
        if self.analysis.getStringResult() or self.analysis.getResultOptions():
            return {"valueString": self.analysis.getFormattedResult()}

        value_quantity = {
            "value": self.analysis.getResult(),
            "unit": self.analysis.getUnit(),
            "system": UCUM_SYSTEM,
            "code": self.analysis.getUnit(),
        }
        return {"valueQuantity": value_quantity}

    def get_reference_range(self):
        rng = self.analysis.getResultsRange()
        if not rng:
            return []

        entry = {}
        for key, bound in (("low", "min"), ("high", "max")):
            value = rng.get(bound)
            if not value:
                continue

            entry[key] = {
                "value": value,
                "unit": self.analysis.getUnit(),
                "system": UCUM_SYSTEM,
                "code": self.analysis.getUnit(),
            }

        if not entry:
            return []

        return [entry]
