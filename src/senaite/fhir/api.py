# -*- coding: utf-8 -*-

import re
from uuid import UUID

from bika.lims import api
from bika.lims.api.security import check_permission
from bika.lims.utils.analysisrequest import create_analysisrequest
from persistent.dict import PersistentDict
from plone.uuid.interfaces import IUUIDGenerator
from Products.Archetypes.utils import mapply
from Products.CMFCore.permissions import ModifyPortalContent
from senaite.fhir import logger
from senaite.fhir.config import FHIR_STORAGE_KEY
from senaite.fhir.config import SYSTEM_CODES
from senaite.fhir.exceptions import FHIRAPIError
from senaite.fhir.interfaces import IContentActionToFHIR
from senaite.fhir.interfaces import IContentToFHIR
from senaite.fhir.interfaces import IFHIRContent
from senaite.fhir.interfaces import IFHIRResource
from senaite.fhir.interfaces import IFHIRToContent
from zope.annotation.interfaces import IAnnotations
from zope.component import getUtility
from zope.component import queryAdapter
from zope.event import notify
from zope.interface import alsoProvides
from zope.lifecycleevent import ObjectModifiedEvent

_marker = object()


def fail(msg, status=500):
    """API Error
    """
    if msg is None:
        msg = "Reason not given."
    raise FHIRAPIError(status, "{}".format(msg))


def is_fhir_content(obj):
    """Returns whether the object passed in was created from a FHIR resource
    """
    return IFHIRContent.providedBy(obj)


def is_fhir_resource(obj):
    """Returns whether the thing is a FHIR Resource object
    """
    return IFHIRResource.providedBy(obj)


def get_fhir_storage(obj):
    """Get or creates the FHIR annotation storage for the given object

    :param obj: Content object
    :returns: PersistentDict
    """
    annotation = IAnnotations(obj)
    if annotation.get(FHIR_STORAGE_KEY) is None:
        annotation[FHIR_STORAGE_KEY] = PersistentDict()
    return annotation[FHIR_STORAGE_KEY]


def is_uuid(thing):
    try:
        get_uuid(thing)
        return True
    except (TypeError, ValueError):
        return False


def get_uuid(thing):
    """Returns the UUID object
    """
    if isinstance(thing, UUID):
        return thing
    if is_fhir_resource(thing):
        return UUID(thing.id)
    if api.is_object(thing):
        return UUID(api.get_uid(thing))
    return UUID(thing)


def get_uid(obj):
    """Returns the UUID in hex format
    """
    if is_fhir_resource(obj):
        return get_uuid(obj).hex
    return api.get_uid(obj)


def get_fhir_uid(obj):
    """Returns the UID of the counterpart FHIR content, if any
    """
    if is_fhir_resource(obj):
        return get_uid(obj)
    obj = api.get_object(obj)
    if is_fhir_content(obj):
        storage = get_fhir_storage(obj)
        return storage.get("uid", None)
    return None


def get_object(thing, default=_marker):
    if is_fhir_resource(thing):
        thing = get_uid(thing)
    if default is _marker:
        return api.get_object(thing)
    return api.get_object(thing, default=default)


def get_available_reasons():
    """Returns available rejection reasons
    """
    setup = api.get_senaite_setup()
    return setup.getRejectionReasons()


def to_fhir_resource(thing, default=_marker):
    """Converts the object to a FHIR resource
    """
    if not thing:
        return None

    if is_fhir_resource(thing):
        return thing

    if isinstance(thing, dict):
        rtype = thing.get("resourceType")
        if not rtype:
            if default is _marker:
                fail(msg="Not well formed resource. Resource type is missing")
            return default

        # Look for FHIRResource named adapters (wrappers)
        resource = queryAdapter(thing, IFHIRResource, rtype)
        if not resource:
            if default is _marker:
                fail(msg="Resource type is not supported: %s" % rtype)
            return default

        return resource

    if api.is_uid(thing):
        thing = api.get_object_by_uid(thing, default=None)
        if not thing:
            if default is _marker:
                fail(msg="Not Found", status=404)
            return default

    obj = api.get_object(thing)
    adapter = queryAdapter(obj, IContentToFHIR)
    if not adapter:
        if default is _marker:
            fail(msg="Type is not supported: %r" % obj)
        return default

    return adapter.to_fhir_resource()


def to_fhir_action_resource(thing, fhir_action, default=_marker):
    """Converts the object action/transition to a FHIR resource
    """
    obj = api.get_object(thing)
    name = "senaite.fhir.action.%s" % fhir_action
    adapter = queryAdapter(obj, IContentActionToFHIR, name=name)
    if not adapter:
        if default is _marker:
            fail(msg="Action is not supported: %s for %r" % (fhir_action, obj))
        return default
    return adapter.to_fhir_resource()


def to_content_dict(resource, default=_marker):
    """Converts the resource to a dict suitable for the creation or edition
    of AT/DX contents their portal type suits well with the resource type.
    Raises a ValueError if there is no IFHIRToContent adapter registered for
    the given resource unless default is set, in which case returns default.
    :rtype: dict
    """
    # convert the resource to a content dict
    adapter = queryAdapter(resource, IFHIRToContent)
    if not adapter:
        msg = "Missing IFHIRToContent adapter for %r" % resource
        if default is _marker:
            raise ValueError(msg)
        logger.warn("Missing IFHIRToContent adapter for %r" % resource)
        return default

    # use the adapter to convert the resource to a content-suitable dict
    return adapter.to_content_dict()


def can_create_or_update(resource):
    """Returns whether the creation of counterpart objects for the given
    resources is supported
    """
    if not is_fhir_resource(resource):
        raise ValueError("Type not supported: {}".format(repr(type(resource))))

    # TODO Make this configurable with a senaite.fhir-specific control panel
    supported_types = [
        "ServiceRequest", "Patient", "Practitioner", "Organization"
    ]
    if resource.resourceType not in supported_types:
        return False

    # Check if there is a FHIRToContent adapter registered
    adapter = queryAdapter(resource, IFHIRToContent)
    if not adapter:
        logger.warn("Can create or update, but FHIRToContent missing: %r" %
                    resource)
        return False
    return True


def create_or_update(resource):
    """Creates a counterpart object for the given FHIR resource if it does
    not exist yet. Updates the existing object otherwise.
    """
    if not is_fhir_resource(resource):
        raise ValueError("Type not supported: {}".format(repr(type(resource))))

    obj = get_object(resource, default=None)
    if not obj:
        return create(resource)
    return update(resource)


def update(resource):
    """Updates the counterpart object for the given FHIR resource
    """
    data = to_content_dict(resource)
    obj = get_object(resource)

    # loop through data and set field values
    fields = api.get_fields(obj)
    for name, value in data.items():
        # check if there is a field
        field = fields.get(name, None)
        if not field:
            continue
        # check if readonly
        readonly = getattr(field, "readonly", False)
        if readonly:
            continue
        # check permissions
        perm = getattr(field, "write_permission", ModifyPortalContent)
        if perm and not check_permission(perm, obj):
            continue

        # Set the value
        if hasattr(field, "getMutator"):
            mutator = field.getMutator(obj)
            mapply(mutator, value)
        else:
            field.set(obj, value)

    # link the FHIR resource to the obj
    link_fhir_resource(obj, resource)
    # re-catalog the object
    obj.reindexObject()
    return obj


def create(resource):
    """Creates a counterpart object for the given FHIR Resource
    """
    # get the uid
    uid = get_uid(resource)

    # check if already exists
    obj = get_object(resource, default=None)
    if obj:
        raise ValueError("Counterpart object already exists: %r" % resource)

    # get the content dict
    data = to_content_dict(resource)

    # create the object
    portal_type = data.pop("portal_type")
    container = data.pop("parent_path")
    container = api.get_object_by_path(container)

    # AnalysisRequest objects are created differently
    # TODO Consider an adapter for create
    if portal_type == "AnalysisRequest":
        request = api.get_request()
        obj = create_analysisrequest(data["Client"], request, data)
    else:
        obj = api.create(container, portal_type, **data)

    # un-catalog the object
    api.uncatalog_object(obj)

    # set the uid of the FHIR resource
    if api.is_dexterity_content(obj):
        setattr(obj, "_plone.uuid", uid)
    elif api.is_at_content(obj):
        setattr(obj, "_at_uid", uid)

    # link the FHIR resource to the obj
    link_fhir_resource(obj, resource)

    # re-catalog the object
    api.catalog_object(obj)

    # TODO Consider to apply this to senaite.core's api.catalog_object
    # api.catalog_object only re-adds AT content to uid_catalog; for DX
    # content we rely on plone.app.referenceablebehavior, which re-indexes
    # the object in uid_catalog on ObjectModifiedEvent. Without this, the
    # patched UID is invisible to api.get_object_by_uid afterwards.
    if api.is_dexterity_content(obj):
        notify(ObjectModifiedEvent(obj))

    return obj


def link_fhir_resource(obj, resource):
    """Assigns a FHIR resource to the given obj
    """
    if not is_fhir_resource(resource):
        raise ValueError("Type not supported: {}".format(repr(type(resource))))

    # mark the object with IFHIRContent, so we can always know beforehand if
    # this object has a counterpart FHIR resource
    alsoProvides(obj, IFHIRContent)

    # assign the FHIR UID, along with current data so we can always use the
    # original information, even when connection with source is lost
    annotation = get_fhir_storage(obj)
    annotation["uid"] = get_uid(resource)
    annotation["data"] = resource.to_dict()


def slugify(value, repl="-"):
    repl = repl if repl else ""
    slug = value.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_-]+", repl, slug)
    slug = re.sub(r"^-+|-+$", "", slug)
    return slug


def get_system_code(resource_type, default=_marker):
    """Returns the system code supported for the given resource type
    """
    # TODO Get this from control panel/registry settings instead
    system = dict(SYSTEM_CODES).get(resource_type)
    if system:
        return system
    if default is _marker:
        raise ValueError("No system code defined for %s" % resource_type)
    return default


def generate_UUID():
    """Generates a new UUID object
    """
    generator = getUtility(IUUIDGenerator)
    return get_uuid(generator())
