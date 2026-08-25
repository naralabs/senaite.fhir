# -*- coding: utf-8 -*-
"""FHIR workflow guards."""

from bika.lims.interfaces import IGuardAdapter
from zope.interface import implementer


@implementer(IGuardAdapter)
class SampleGuardAdapter(object):
    """Apply FHIR-specific guards to sample workflow transitions
    """

    def __init__(self, context):
        self.context = context

    def guard(self, transition):
        if transition != "receive":
            return True
        return bool((self.context.getClientSampleID()))
