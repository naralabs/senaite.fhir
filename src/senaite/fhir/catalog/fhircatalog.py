# -*- coding: utf-8 -*-

from App.class_init import InitializeClass
from senaite.core.catalog.base_catalog import BaseCatalog
from senaite.fhir.interfaces import IFHIRCatalog
from zope.interface import implementer

CATALOG_ID = "senaite_catalog_fhir"
CATALOG_TITLE = "Senaite FHIR Catalog"

INDEXES = [
    # id, indexed attribute, type
    ("allowedRolesAndUsers", "", "KeywordIndex"),
    ("fhir_uids", "", "KeywordIndex"),
    ("portal_type", "", "FieldIndex"),
    ("UID", "", "UUIDIndex"),
]

COLUMNS = [
    # attribute name
    "allowedRolesAndUsers",
    "fhir_resource_types",
    "portal_type",
    "UID",
]

TYPES = [
    # portal_type name
]


@implementer(IFHIRCatalog)
class FHIRCatalog(BaseCatalog):
    """Catalog for mapping Content-To-FHIR relationships
    """
    def __init__(self):
        BaseCatalog.__init__(self, CATALOG_ID, title=CATALOG_TITLE)

    @property
    def mapped_catalog_types(self):
        return TYPES


InitializeClass(FHIRCatalog)
