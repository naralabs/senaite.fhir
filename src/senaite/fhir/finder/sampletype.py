# -*- coding: utf-8 -*-

from bika.lims import api
from senaite.core.catalog import SETUP_CATALOG
from senaite.fhir.interfaces import IContentFinder
from senaite.fhir.interfaces import ISpecimenResource
from zope.component import adapter
from zope.interface import implementer


@adapter(ISpecimenResource)
@implementer(IContentFinder)
class SampleTypeFinder(object):
    """Adapter in charge of searching the counterpart SampleType object of a
    FHIR Specimen resource
    """

    def __init__(self, resource):
        self.resource = resource

    def find(self):
        """Looks for the resource's counterpart Specimen object
        """
        # TODO Add a SNOMED field to SampleType to search by code instead
        code = self.resource.get_code()
        display = code.display.lower()

        # use sortable_title to ignore case on search
        query = dict(portal_type="SampleType", sortable_title=display.lower())
        brains = api.search(query, SETUP_CATALOG)
        if len(brains) == 1:
            return api.get_object(brains[0])

        return None
