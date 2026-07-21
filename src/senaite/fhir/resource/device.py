# -*- coding: utf-8 -*-

from senaite.fhir.interfaces import IDeviceResource
from senaite.fhir.resource import FHIRResource
from zope.interface import implementer


@implementer(IDeviceResource)
class DeviceResource(FHIRResource):
    pass
