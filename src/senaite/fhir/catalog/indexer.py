# -*- coding: utf-8 -*-

import json
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


# TODO Replace IContentish by IFHIRContentish (not IFHIRContent)
@indexer(IContentish, IFHIRCatalog)
def fhir_resource_types(obj):
    """Returns a json dict wih resourceTypes as keys and uids as values
    """
    uids = fapi.get_fhir_uids(obj) or {}
    return json.dumps(uids)
