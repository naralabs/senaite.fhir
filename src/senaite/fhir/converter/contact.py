# -*- coding: utf-8 -*-

from senaite.fhir import api as fapi
from bika.lims import api
from senaite.fhir.converter.person import ResourceToPerson
from senaite.fhir.interfaces import IFHIRToContent
from senaite.fhir.interfaces import IPractitionerResource
from zope.component import adapter
from zope.interface import implementer


@adapter(IPractitionerResource)
@implementer(IFHIRToContent)
class ResourceToContact(ResourceToPerson):

    def get_parent(self):
        """Returns the parent object to which the counterpart object should
        belong to
        """
        bundle = self.resource.get("_bundle")
        if not bundle:
            return None
        org = bundle.first_entry("resourceType", "Organization")
        # Organization has no preserved incoming id (see ``fapi.create``), so
        # an exact FHIR-uid match always misses; ``find_object_for`` falls
        # back to ``ClientFinder``'s business-key match, same as
        # ``get_client``/``get_patient`` below do for their own siblings.
        return fapi.find_object_for(org, default=None)

    def to_content_dict(self):
        # contact should belong to a client (Organization)
        parent = self.get_parent()
        if not parent:
            raise ValueError("%r: Cannot infer parent" % self.resource)

        # build the dict
        data = super(ResourceToContact, self).to_content_dict()
        data.update({
            "portal_type": "Contact",
            "parent_path": api.get_path(parent),
        })
        return data
