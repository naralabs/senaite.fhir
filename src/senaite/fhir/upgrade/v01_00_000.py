# -*- coding: utf-8 -*-

from senaite.fhir import logger
from senaite.fhir.setuphandlers import setup_workflows


def upgrade_worksheet_workflow(tool):
    """Add the ready and in-progress states to existing installations."""
    portal = tool.aq_inner.aq_parent
    logger.info("Upgrading FHIR worksheet workflow ...")
    setup_workflows(portal)
    logger.info("Upgrading FHIR worksheet workflow [DONE]")
