# -*- coding: utf-8 -*-

from collections import OrderedDict

from senaite.fhir.interfaces import IResultsBundleResource
from senaite.fhir.resource import FHIRResource
from zope.interface import implementer

FIELD_ORDER = (
    "resourceType",
    "id",
    "meta",
    "type",
    "timestamp",
    "total",
    "entry",
)


@implementer(IResultsBundleResource)
class ResultsBundleResource(FHIRResource, OrderedDict):
    """A searchset Bundle returned by the DiagnosticReport polling endpoint.
    Contains SenaiteDiagnosticReport match entries and SenaiteObservation
    include entries. The presentedForm.data (PDF) is excluded when the request
    uses _summary=true.
    https://fhir.senaite.org/StructureDefinition-SenaiteResultsBundle.html
    """

    def _initialize(self):
        data = dict(self)
        self.clear()
        for k in FIELD_ORDER:
            if k in data:
                self[k] = data[k]
        for k, v in data.iteritems():
            if k not in FIELD_ORDER:
                self[k] = v

    @property
    def type(self):
        return self.get("type", "searchset")

    @property
    def total(self):
        return self.get("total", 0)

    @property
    def entry(self):
        """Returns raw entry dicts preserving fullUrl, resource, and search
        metadata — unlike the incoming Bundle which strips entries down to
        FHIRResource objects only.
        """
        return self.get("entry") or []
