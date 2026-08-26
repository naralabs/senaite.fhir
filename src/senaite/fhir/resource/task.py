# -*- coding: utf-8 -*-

from senaite.fhir.interfaces import ITaskResource
from senaite.fhir.resource import FHIRResource
from zope.interface import implementer


@implementer(ITaskResource)
class TaskResource(FHIRResource):
    """FHIR Task resource used for a SENAITE instrument worksheet."""

    __fixed_values = (
        ("resourceType", "Task"),
        ("intent", "order"),
    )
