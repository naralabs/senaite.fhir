# -*- coding: utf-8 -*-

from plone.indexer import indexer
from Products.CMFCore.interfaces import IContentish
from senaite.fhir.interfaces import IFHIRCatalog
from senaite.fhir import api as fapi


# TODO Replace IContentish by IFHIRContentish (not IFHIRContent)
@indexer(IContentish, IFHIRCatalog)
def fhir_uids(obj):
    """Return a list with the counterpart FHIR uids of the given object
    """
    # get the uids grouped by resource type
    uids = fapi.get_fhir_uids(obj)
    return uids.values()
