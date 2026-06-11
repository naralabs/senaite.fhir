SENAITE FHIR API
----------------

This doctest exercises the helpers exposed in ``senaite.fhir.api``. The
package-level convention is to alias it as ``fapi`` so it can co-exist
with the core SENAITE API which is imported as ``api``::

    >>> from bika.lims import api
    >>> from senaite.fhir import api as fapi

Running this test from the buildout directory::

    bin/test test_doctests -t api


Test Setup
~~~~~~~~~~

Needed imports::

    >>> import transaction
    >>> from uuid import UUID
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID

    >>> from senaite.fhir.exceptions import FHIRAPIError
    >>> from senaite.fhir.interfaces import IFHIRContent
    >>> from senaite.fhir.interfaces import IFHIRResource
    >>> from senaite.fhir.resource.patient import PatientResource

Variables::

    >>> portal = self.portal
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])
    >>> transaction.commit()


slugify
~~~~~~~

``fapi.slugify`` lowercases the input, strips non-word characters and
collapses runs of whitespace, underscores and hyphens into a single
separator (``-`` by default), trimming leading/trailing separators::

    >>> fapi.slugify("Hello World")
    'hello-world'

    >>> fapi.slugify("Patient ID #42")
    'patient-id-42'

    >>> fapi.slugify("  --leading and trailing--  ")
    'leading-and-trailing'

    >>> fapi.slugify("Mixed   case_and__underscores")
    'mixed-case-and-underscores'

The separator can be customised or removed::

    >>> fapi.slugify("Hello World", repl="_")
    'hello_world'

    >>> fapi.slugify("Hello World", repl="")
    'helloworld'


get_fhir_resource_id / set_fhir_resource_id
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``get_fhir_resource_id`` returns ``None`` (without creating annotation storage)
for objects that have never been assigned a FHIR ID::

    >>> plain = api.create(
    ...     portal.patients, "Patient",
    ...     mrn=u"PAT-PLAIN",
    ...     firstname=u"Alice",
    ...     lastname=u"Smith",
    ... )
    >>> fapi.get_fhir_resource_id(plain, "Patient") is None
    True

``set_fhir_resource_id`` writes the id and creates storage on demand::

    >>> fapi.set_fhir_resource_id(plain, "Patient", "aabbccdd" * 4)
    >>> fapi.get_fhir_resource_id(plain, "Patient")
    'aabbccddaabbccddaabbccddaabbccdd'

The helper is generic and supports any resource type on the same object::

    >>> fapi.set_fhir_resource_id(plain, "DiagnosticReport", "11223344" * 4)
    >>> fapi.get_fhir_resource_id(plain, "DiagnosticReport")
    '11223344112233441122334411223344'

Each type uses its own key so they do not collide::

    >>> fapi.get_fhir_resource_id(plain, "Patient")
    'aabbccddaabbccddaabbccddaabbccdd'


get_object_by_fhir_id
~~~~~~~~~~~~~~~~~~~~~

``get_object_by_fhir_id`` scans the catalog for an object whose stored FHIR ID
matches the given value.  It returns ``None`` when no match is found.

Compare by UID rather than Python identity, because the catalog returns
acquisition-wrapped objects that are not ``is``-identical to the original::

    >>> found = fapi.get_object_by_fhir_id(
    ...     "aabbccddaabbccddaabbccddaabbccdd", "Patient", "Patient")
    >>> fapi.get_uid(found) == fapi.get_uid(plain)
    True

    >>> fapi.get_object_by_fhir_id("00000000000000000000000000000000",
    ...                             "Patient", "Patient") is None
    True


fail
~~~~

``fapi.fail`` raises a ``FHIRAPIError`` carrying the requested HTTP
status code::

    >>> fapi.fail("Not Found", status=404)
    Traceback (most recent call last):
    ...
    FHIRAPIError: Not Found

The HTTP status is attached to the exception and applied to the
current request response::

    >>> try:
    ...     fapi.fail("Not Found", status=404)
    ... except FHIRAPIError as e:
    ...     e.status
    404

A default message is used when ``None`` is passed::

    >>> fapi.fail(None)
    Traceback (most recent call last):
    ...
    FHIRAPIError: Reason not given.


is_uuid / get_uuid
~~~~~~~~~~~~~~~~~~

``fapi.is_uuid`` accepts either the canonical dashed form or the
32-char hex form. Anything that can't be parsed into a ``uuid.UUID`` is
rejected::

    >>> fapi.is_uuid("52f941c6-81a0-51be-b1a6-f92ac079be34")
    True

    >>> fapi.is_uuid("52f941c681a051beb1a6f92ac079be34")
    True

    >>> fapi.is_uuid("not-a-uuid")
    False

    >>> fapi.is_uuid(None)
    False

``fapi.get_uuid`` parses either form into a ``uuid.UUID``::

    >>> fapi.get_uuid("52f941c6-81a0-51be-b1a6-f92ac079be34")
    UUID('52f941c6-81a0-51be-b1a6-f92ac079be34')

    >>> fapi.get_uuid("52f941c681a051beb1a6f92ac079be34")
    UUID('52f941c6-81a0-51be-b1a6-f92ac079be34')

A ``UUID`` instance is returned unchanged::

    >>> u = UUID("52f941c6-81a0-51be-b1a6-f92ac079be34")
    >>> fapi.get_uuid(u) is u
    True


Create a plain Patient
~~~~~~~~~~~~~~~~~~~~~~

Most of the remaining helpers operate on content objects, so we first
create a Patient through the core SENAITE API::

    >>> patient = api.create(
    ...     portal.patients, "Patient",
    ...     mrn=u"PAT-001",
    ...     firstname=u"Jane",
    ...     lastname=u"Doe",
    ...     sex=u"f",
    ...     gender=u"f",
    ...     birthdate="1980-01-01",
    ... )
    >>> patient
    <Patient at /plone/patients/...>


get_uid / get_uuid on content
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``fapi.get_uid`` returns a 32-char hex UID, and ``fapi.get_uuid``
returns the corresponding ``uuid.UUID``::

    >>> patient_uid = fapi.get_uid(patient)
    >>> len(patient_uid)
    32
    >>> fapi.is_uuid(patient_uid)
    True
    >>> fapi.get_uuid(patient).hex == patient_uid
    True


is_fhir_content / is_fhir_resource / get_fhir_uid
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A freshly-created Patient is not yet linked to any FHIR resource::

    >>> fapi.is_fhir_content(patient)
    False

    >>> fapi.is_fhir_resource(patient)
    False

    >>> fapi.get_fhir_uid(patient) is None
    True


to_fhir_resource
~~~~~~~~~~~~~~~~

``fapi.to_fhir_resource`` accepts a dict and dispatches to the named
``IFHIRResource`` adapter for its ``resourceType``::

    >>> data = {
    ...     "resourceType": "Patient",
    ...     "id": "52f941c6-81a0-51be-b1a6-f92ac079be34",
    ...     "name": [{"use": "official", "family": "Roe", "given": ["John"]}],
    ...     "gender": "male",
    ...     "birthDate": "1975-05-20",
    ...     "identifier": [
    ...         {"use": "secondary", "value": "PAT-999"},
    ...     ],
    ... }
    >>> resource = fapi.to_fhir_resource(data)
    >>> isinstance(resource, PatientResource)
    True
    >>> fapi.is_fhir_resource(resource)
    True
    >>> IFHIRResource.providedBy(resource)
    True

The call is idempotent on resources::

    >>> fapi.to_fhir_resource(resource) is resource
    True

A FHIR resource also exposes its UID via the same helpers::

    >>> fapi.get_uid(resource)
    '52f941c681a051beb1a6f92ac079be34'

    >>> fapi.get_uuid(resource)
    UUID('52f941c6-81a0-51be-b1a6-f92ac079be34')

It also accepts a content object and dispatches to the registered
``IContentToFHIR`` adapter::

    >>> resource_from_patient = fapi.to_fhir_resource(patient)
    >>> isinstance(resource_from_patient, PatientResource)
    True

    >>> resource_from_patient["resourceType"]
    'Patient'

    >>> resource_from_patient["gender"]
    'female'

And accepts a UID, resolving the matching content first::

    >>> resource_from_uid = fapi.to_fhir_resource(patient_uid)
    >>> isinstance(resource_from_uid, PatientResource)
    True

Empty / falsy input returns ``None``::

    >>> fapi.to_fhir_resource(None) is None
    True

    >>> fapi.to_fhir_resource({}) is None
    True

Unsupported or malformed dicts fail unless ``default`` is provided::

    >>> fapi.to_fhir_resource({"resourceType": "Unsupported"})
    Traceback (most recent call last):
    ...
    FHIRAPIError: Resource type is not supported: Unsupported

    >>> fapi.to_fhir_resource({"resourceType": "Unsupported"},
    ...                       default=None) is None
    True

    >>> fapi.to_fhir_resource({"id": "x"})
    Traceback (most recent call last):
    ...
    FHIRAPIError: Not well formed resource. Resource type is missing

Unknown UIDs fail unless ``default`` is provided::

    >>> fapi.to_fhir_resource("00000000000000000000000000000000")
    Traceback (most recent call last):
    ...
    FHIRAPIError: Not Found

    >>> fapi.to_fhir_resource("00000000000000000000000000000000",
    ...                       default=None) is None
    True


to_content_dict
~~~~~~~~~~~~~~~

``fapi.to_content_dict`` converts a FHIR resource into a kwargs dict
suitable for ``api.create`` / ``api.edit`` via the registered
``IFHIRToContent`` adapter::

    >>> content = fapi.to_content_dict(resource)
    >>> content["portal_type"]
    'Patient'
    >>> content["parent_path"]
    '/plone/patients'
    >>> content["mrn"]
    u'PAT-999'
    >>> content["firstname"]
    u'John'
    >>> content["lastname"]
    u'Roe'
    >>> content["sex"]
    u'm'
    >>> content["gender"]
    u'm'

When no ``IFHIRToContent`` adapter is registered the call raises
``ValueError`` (or returns the supplied default)::

    >>> class _Dummy(object):
    ...     pass
    >>> fapi.to_content_dict(_Dummy())
    Traceback (most recent call last):
    ...
    ValueError: Missing IFHIRToContent adapter for ...

    >>> fapi.to_content_dict(_Dummy(), default=None) is None
    True


can_create_or_update
~~~~~~~~~~~~~~~~~~~~

``fapi.can_create_or_update`` tells whether a FHIR resource has a
supported counterpart in this SENAITE deployment. It checks both that
the ``resourceType`` is in the allow-list and that an ``IFHIRToContent``
adapter is registered for it::

    >>> fapi.can_create_or_update(resource)
    True

Resource types outside the allow-list return ``False`` (no exception)::

    >>> unsupported = fapi.to_fhir_resource({
    ...     "resourceType": "Patient",
    ...     "id": "33333333-3333-5333-9333-333333333333",
    ... })
    >>> unsupported["resourceType"] = "Encounter"
    >>> fapi.can_create_or_update(unsupported)
    False

Non-resources are rejected with ``ValueError``::

    >>> fapi.can_create_or_update({"foo": "bar"})
    Traceback (most recent call last):
    ...
    ValueError: Type not supported: <type 'dict'>


link_fhir_resource / get_fhir_storage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``fapi.link_fhir_resource`` marks an object as ``IFHIRContent`` and
writes the resource's UID + serialized data into the FHIR annotation
storage. It is what ``create`` / ``update`` use internally::

    >>> fapi.link_fhir_resource(patient, resource)
    >>> fapi.is_fhir_content(patient)
    True
    >>> IFHIRContent.providedBy(patient)
    True
    >>> fapi.get_fhir_uid(patient) == fapi.get_uid(resource)
    True

``fapi.get_fhir_storage`` returns the (lazily-created)
``PersistentDict`` holding the linked resource's payload::

    >>> storage = fapi.get_fhir_storage(patient)
    >>> sorted(storage.keys())
    ['data', 'fhir_patient_id', 'uid']

    >>> storage["uid"] == fapi.get_uid(resource)
    True

    >>> storage["data"]["resourceType"]
    'Patient'

The storage is created on first access and re-used afterwards::

    >>> fapi.get_fhir_storage(patient) is storage
    True

``link_fhir_resource`` rejects non-resources::

    >>> fapi.link_fhir_resource(patient, {"foo": "bar"})
    Traceback (most recent call last):
    ...
    ValueError: Type not supported: <type 'dict'>


create
~~~~~~

``fapi.create`` creates a counterpart content object for the given FHIR
resource and links the two via ``link_fhir_resource``.  For resource types
listed in ``FHIR_RESOURCE_TO_PORTAL_TYPE`` (Patient is one of them) the FHIR
logical id is stored as a separate annotation field so that the SENAITE UID
keeps its own generated value::

    >>> fresh = fapi.to_fhir_resource({
    ...     "resourceType": "Patient",
    ...     "id": "11111111-1111-5111-9111-111111111111",
    ...     "name": [{"use": "official", "family": "Newman", "given": ["Anne"]}],
    ...     "gender": "female",
    ...     "birthDate": "1990-06-15",
    ...     "identifier": [{"use": "secondary", "value": "PAT-NEW"}],
    ... })
    >>> created = fapi.create(fresh)
    >>> created
    <Patient at /plone/patients/...>

The SENAITE UID is not overwritten; it keeps its own generated value::

    >>> fapi.get_uid(created) == fapi.get_uid(fresh)
    False

The incoming FHIR id is preserved in the annotation storage::

    >>> fapi.get_fhir_resource_id(created, "Patient") == fapi.get_uid(fresh)
    True

    >>> fapi.get_fhir_uid(created) == fapi.get_uid(fresh)
    True

    >>> fapi.is_fhir_content(created)
    True

    >>> created.getFirstname()
    'Anne'

    >>> created.getLastname()
    'Newman'

    >>> transaction.commit()


get_object
~~~~~~~~~~

``fapi.get_object`` resolves a FHIR resource into the linked content.
Passing a FHIR resource object supplies the resource-type context needed
to trigger the FHIR-ID fallback scan::

    >>> fapi.get_uid(fapi.get_object(fresh)) == fapi.get_uid(created)
    True

Passing a bare FHIR ID string has no resource-type context, so the
fallback scan is skipped and the lookup fails (use ``get_object_by_fhir_id``
when you need to look up by a known FHIR ID and portal type)::

    >>> fhir_id = fapi.get_uid(fresh)
    >>> fapi.get_object(fhir_id, default=None) is None
    True

    >>> found = fapi.get_object_by_fhir_id(fhir_id, "Patient", "Patient")
    >>> fapi.get_uid(found) == fapi.get_uid(created)
    True

An unknown UID raises unless a default is provided::

    >>> orphan = fapi.to_fhir_resource({
    ...     "resourceType": "Patient",
    ...     "id": "99999999-9999-5999-9999-999999999999",
    ... })
    >>> fapi.get_object(orphan)
    Traceback (most recent call last):
    ...
    APIError: No object found for UID 99999999999959999999999999999999

    >>> fapi.get_object(orphan, default=None) is None
    True


update
~~~~~~

``fapi.update`` re-applies the resource fields to the existing linked
content::

    >>> fresh["name"] = [
    ...     {"use": "official", "family": "Smith", "given": ["Anne"]},
    ... ]
    >>> updated = fapi.update(fresh)
    >>> fapi.get_uid(updated) == fapi.get_uid(created)
    True
    >>> updated.getLastname()
    'Smith'


create_or_update
~~~~~~~~~~~~~~~~

``fapi.create_or_update`` dispatches to ``update`` when a counterpart
exists, and to ``create`` otherwise::

    >>> fresh["name"] = [
    ...     {"use": "official", "family": "Stone", "given": ["Anne"]},
    ... ]
    >>> result = fapi.create_or_update(fresh)
    >>> fapi.get_uid(result) == fapi.get_uid(created)
    True
    >>> result.getLastname()
    'Stone'

A brand-new resource produces a new content object::

    >>> brand_new = fapi.to_fhir_resource({
    ...     "resourceType": "Patient",
    ...     "id": "22222222-2222-5222-9222-222222222222",
    ...     "name": [{"use": "official", "family": "Mint", "given": ["Fresh"]}],
    ...     "gender": "male",
    ...     "birthDate": "2000-01-01",
    ...     "identifier": [{"use": "secondary", "value": "PAT-MINT"}],
    ... })
    >>> minted = fapi.create_or_update(brand_new)
    >>> fapi.is_fhir_content(minted)
    True
    >>> minted.getLastname()
    'Mint'

The FHIR id is stored separately; the SENAITE UID is distinct::

    >>> fapi.get_fhir_resource_id(minted, "Patient") == fapi.get_uid(brand_new)
    True
    >>> fapi.get_uid(minted) == fapi.get_uid(brand_new)
    False


Duplicate create
~~~~~~~~~~~~~~~~

Calling ``create`` a second time for the same resource fails, because
the counterpart already exists::

    >>> fapi.create(brand_new)
    Traceback (most recent call last):
    ...
    ValueError: Counterpart object already exists: <PatientResource ...>
