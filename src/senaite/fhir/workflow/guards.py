# -*- coding: utf-8 -*-
"""Workflow guards for FHIR worksheet worklists."""

from bika.lims import api
from bika.lims.interfaces import IGuardAdapter
from senaite.core.interfaces import IWorksheet
from zope.interface import implementer


LOCKED_WORKSHEET_STATES = (
    "ready",
    "in_progress",
    "to_be_verified",
    "verified",
)


@implementer(IGuardAdapter)
class AnalysisGuardAdapter(object):
    """Prevent changing an analysis assigned to a locked worksheet

    Worksheet.addAnalysis already refuses non-open worksheets.  This adapter
    additionally covers unassign transitions, including calls that bypass the
    worksheet view, so a ready worksheet cannot lose an analysis.
    """

    def __init__(self, context):
        self.context = context

    def guard(self, transition):
        if transition == "assign":
            worksheet = self.worksheet_from_request()
        elif transition == "unassign":
            worksheet = self.context.getWorksheet()
        else:
            return True

        if not IWorksheet.providedBy(worksheet):
            return True
        return api.get_review_status(worksheet) not in LOCKED_WORKSHEET_STATES

    def worksheet_from_request(self):
        request = api.get_request()
        for parent in request.get("PARENTS", []):
            if IWorksheet.providedBy(parent):
                return parent
        return api.get_object_by_uid(request.get("ws_uid", ""), None)


@implementer(IGuardAdapter)
class WorksheetGuardAdapter(object):
    """Prevent an empty worksheet from becoming an instrument worklist
    """

    def __init__(self, context):
        self.context = context

    def guard(self, transition):
        if transition not in ("ready", "in_progress"):
            return True
        return bool(self.context.getAnalyses())
