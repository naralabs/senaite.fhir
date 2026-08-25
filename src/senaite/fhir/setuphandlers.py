# -*- coding: utf-8 -*-
from senaite.core.setuphandlers import setup_core_catalogs
from senaite.core.setuphandlers import setup_other_catalogs
from senaite.core import permissions
from senaite.core.api import workflow as wapi
from senaite.core.workflow import SAMPLE_WORKFLOW
from senaite.fhir import logger
from senaite.fhir import PRODUCT_NAME
from senaite.fhir.catalog import FHIRCatalog


CATALOGS = (
    FHIRCatalog,
)

# Tuples of (catalog, index_name, index_attribute, index_type)
INDEXES = [
]

# Tuples of (catalog, column_name)
COLUMNS = [
]

# Workflow updates
WORKFLOWS_TO_UPDATE = {
    SAMPLE_WORKFLOW: {
        "states": {
            "sample_received": {
                "permissions": {
                    permissions.FieldEditClientSampleID: (),
                },
            },
            "to_be_verified": {
                "permissions": {
                    permissions.FieldEditClientSampleID: (),
                },
            },
            "to_be_preserved": {
                "permissions": {
                    permissions.FieldEditClientSampleID: (),
                },
            },
        },
    },
}


def setup_handler(context):
    """Generic setup handler
    """
    if context.readDataFile("{}.txt".format(PRODUCT_NAME)) is None:
        return

    logger.info("{} setup handler [BEGIN]".format(PRODUCT_NAME.upper()))
    portal = context.getSite()

    # Setup catalogs
    setup_catalogs(portal)

    # Lock the Client Sample ID once a sample is received.
    setup_workflows(portal)

    logger.info("{} setup handler [DONE]".format(PRODUCT_NAME.upper()))


def pre_install(portal_setup):
    """Runs before the first import step of the *default* profile
    This handler is registered as a *pre_handler* in the generic setup profile
    :param portal_setup: SetupTool
    """
    logger.info("{} pre-install handler [BEGIN]".format(PRODUCT_NAME.upper()))
    profile_id = "profile-{}:default".format(PRODUCT_NAME)
    context = portal_setup._getImportContext(profile_id)  # noqa
    portal = context.getSite()  # noqa

    logger.info("{} pre-install handler [DONE]".format(PRODUCT_NAME.upper()))


def post_install(portal_setup):
    """Runs after the last import step of the *default* profile
    This handler is registered as a *post_handler* in the generic setup profile
    :param portal_setup: SetupTool
    """
    logger.info("{} install handler [BEGIN]".format(PRODUCT_NAME.upper()))
    profile_id = "profile-{}:default".format(PRODUCT_NAME)
    context = portal_setup._getImportContext(profile_id)  # noqa
    portal = context.getSite()  # noqa

    logger.info("{} install handler [DONE]".format(PRODUCT_NAME.upper()))


def post_uninstall(portal_setup):
    """Runs after the last import step of the *uninstall* profile
    This handler is registered as a *post_handler* in the generic setup profile
    :param portal_setup: SetupTool
    """
    logger.info("{} uninstall handler [BEGIN]".format(PRODUCT_NAME.upper()))

    # https://docs.plone.org/develop/addons/components/genericsetup.html#custom-installer-code-setuphandlers-py
    profile_id = "profile-{}:uninstall".format(PRODUCT_NAME)
    context = portal_setup._getImportContext(profile_id)  # noqa
    portal = context.getSite()  # noqa

    logger.info("{} uninstall handler [DONE]".format(PRODUCT_NAME.upper()))


def setup_catalogs(portal):
    """Setup patient catalogs
    """
    setup_core_catalogs(portal, catalog_classes=CATALOGS)
    setup_other_catalogs(portal, indexes=INDEXES, columns=COLUMNS)


def setup_workflows(portal):
    """Apply FHIR-specific workflow restrictions
    """
    logger.info("Setup workflows ...")
    for workflow_id, settings in WORKFLOWS_TO_UPDATE.items():
        wapi.update_workflow(workflow_id, **settings)
    logger.info("Setup workflows [DONE]")
