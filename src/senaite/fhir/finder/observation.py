# -*- coding: utf-8 -*-

from senaite.fhir import api as fapi
from senaite.fhir.interfaces import IContentFinder
from senaite.fhir.interfaces import IObservationResource
from zope.component import adapter
from zope.interface import implementer


@adapter(IObservationResource)
@implementer(IContentFinder)
class AnalysisFinder(object):
    """Adapter in charge of searching the counterpart Analysis object of an
    incoming Observation resource.

    The Analysis is not referenced directly: Observation.basedOn points to
    the instrument-scoped SenaiteInstrumentServiceRequest (see
    AnalysisToInstrumentServiceRequest) handed to the analyzer, so the
    Analysis is resolved through that ServiceRequest's FHIR uid instead of
    the Observation's own id.
    """

    def __init__(self, resource):
        self.resource = resource

    def find(self):
        """Looks for the Analysis referenced by Observation.basedOn[0]
        """
        based_on = self.resource.basedOn
        if not based_on:
            return None

        uid = based_on[0].UID()
        if not uid:
            return None

        return fapi.get_object_by_fhir_uid(
            uid, portal_type="Analysis", default=None)
