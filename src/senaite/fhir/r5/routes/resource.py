# -*- coding: utf-8 -*-

import transaction

from bika.lims import api
from bika.lims.interfaces import IAnalysisRequest
from bika.lims.workflow import doActionFor as do_action_for
from senaite.core.api import dtime
from senaite.core.api import workflow as wapi
from senaite.fhir import api as fapi
from senaite.fhir.api import find_object_for
from senaite.fhir.converter import to_fhir_profile_url
from senaite.fhir.finder.sampletype import SampleTypeFinder
from senaite.fhir.interfaces import IBundleResource
from senaite.fhir.interfaces import ISpecimenResource
from senaite.fhir.r5 import add_route
from senaite.fhir.resource.bundleresponse import BundleResponseResource
from senaite.fhir.resource.operationoutcome import OperationOutcome
from senaite.fhir.resource.resultsbundle import ResultsBundleResource
from senaite.fhir.exceptions import ServiceRequestValidationError
from senaite.fhir.resource.servicerequestrevoked import ServiceRequestRevocationError  # noqa: E501
from senaite.fhir.resource.servicerequestrevoked import ServiceRequestRevocationResource  # noqa: E501
from senaite.jsonapi import api as japi
from senaite.jsonapi import request as req

ENDPOINT = "senaite.fhir.r5"
ENDPOINT_GET = "%s.get" % ENDPOINT
ENDPOINT_POST = "%s.post" % ENDPOINT
ENDPOINT_REVOKE = "%s.revoke" % ENDPOINT

RESOURCE_TYPE_TO_CONTENT = (
    ("ServiceRequest", IAnalysisRequest),
)


# /<resource_type>
@add_route("/<string:resource_type>",
           ENDPOINT_GET, methods=["GET"])
@add_route("/<string:resource_type>/<string(length=32):uid>",
           ENDPOINT_GET, methods=["GET"])
@add_route("/<string(length=32):uid>",
           ENDPOINT_GET, methods=["GET"])
@add_route("/<string:resource_type>/<string(length=36):uid>",
           ENDPOINT_GET, methods=["GET"])
@add_route("/<string(length=36):uid>",
           ENDPOINT_GET, methods=["GET"])
def get(context, request, resource_type=None, uid=None):
    """GET
    """
    # maybe we received a request by uid/uuid
    uuids = list(filter(lambda val: fapi.is_uuid(val), [uid, resource_type]))
    if uuids:
        uid = fapi.get_uuid(uuids[0]).hex
        # pass the resource type so to_fhir_resource can fall back to a
        # fhir_<resource_type>_id search when the SENAITE UID lookup misses
        fhir_type = resource_type if not fapi.is_uuid(resource_type) else None
        resource = fapi.to_fhir_resource(
            uid, resource_type=fhir_type, default=None
        )
        if resource:
            return resource

        fapi.fail(msg="Not Found", status=404)

    # DiagnosticReport search (polling endpoint)
    if resource_type == "DiagnosticReport" and not uid:
        return get_diagnostic_report_bundle(context, request)

    # Specimen listing: annotation-backed, no native SENAITE content type
    if resource_type == "Specimen" and not uid:
        return get_specimen_bundle(context, request)

    # all resources from the defined type
    portal_type = japi.resource_to_portal_type(resource_type)
    if portal_type is None:
        fapi.fail(msg="Not Found", status=404)

    # TODO Return a FHIR batch of resources?
    return japi.get_batched(portal_type=portal_type, uid=uid,
                            endpoint=ENDPOINT_GET)


@add_route("/<string:resource_type>", ENDPOINT_POST, methods=["POST"])
def post(context, request, resource_type=None):
    # disable CSRF
    req.disable_csrf_protection()

    # get the FHIR resources from the request
    resources = get_fhir_resources()

    # Pre-flight: if any Specimen in the bundle has no matching SampleType in
    # SENAITE the entire bundle must be rejected before any content is touched
    issue = check_existing_sample_type(resources)
    if issue:
        request.response.setStatus(400)
        return OperationOutcome({"issue": [issue]})

    entries = []
    errored = False
    for resource in resources:

        # Skip if creation or update of this resource is not supported
        if not fapi.can_create_or_update(resource):
            continue

        # create or update the counterpart object
        obj = find_object_for(resource)
        try:
            if not obj:
                obj = fapi.create(resource)
                status = "201 Created"
            else:
                obj = fapi.update(obj, resource)
                status = "201 Updated"
        except ServiceRequestValidationError as e:
            transaction.abort()
            request.response.setStatus(400)
            issue = {
                "severity": "error",
                "code": "business-rule",
                "details": {"text": str(e)},
                "expression": e.expression,
            }
            return OperationOutcome({"issue": [issue]})
        except Exception as e:
            errored = True
            status = "500 %s" % str(e)
            # flush entries to only report back the errored resource
            entries = []
            # prevent partial commits
            transaction.abort()

        # build the response entry
        fullUrl = "%s/%s" % (resource.resourceType, resource.id)
        modified = api.get_modification_date(obj) if obj else dtime.now()
        modified = dtime.to_iso_format(modified)

        # set up the basics of the response entry for this item
        entry = {
            "fullUrl": fullUrl,
            "response": {
                "status": status,
                "lastModified": modified,
            }
        }
        entries.append(entry)

        # Skip further processing if errored
        if errored:
            break

        # If the resource is a ServiceRequest, process any Specimen resources
        if resource.resourceType == "ServiceRequest" and obj:
            specimen_entries = process_bundle_specimen(
                resource, obj, status, modified
            )
            entries.extend(specimen_entries)

    # create the BundleResponse
    resp = {
        "resourceType": "Bundle",
        "id": str(fapi.generate_UUID()),
        "meta": {
            "profile": [to_fhir_profile_url("SenaiteBundleResponse")]
        },
        "type": "transaction-response",
        "entry": entries,
    }
    return BundleResponseResource(resp)


def check_existing_sample_type(resources):
    """Return an OperationOutcome issue dict if any Specimen in the resource
    list cannot be mapped to an existing SampleType in SENAITE, or None when
    all Specimens are resolvable
    """
    for resource in resources:
        if not ISpecimenResource.providedBy(resource):
            continue

        if not SampleTypeFinder(resource).find():
            return {
                "severity": "error",
                "code": "not-found",
                "details": {
                    "text": "Specimen has no matching SampleType in SENAITE"
                },
                "expression": ["Specimen.type"],
            }
    return None


def process_bundle_specimen(sr_resource, ar_obj, ar_status, ar_modified):
    """Store each Specimen referenced by a ServiceRequest into the AR's
    annotation storage and return bundle-response entries for them.

    Specimen has no independent SENAITE content type: it is persisted as
    annotation data on the AnalysisRequest so it can be fetched later via
    GET /Specimen/<uid> without callers needing to know SENAITE internals.
    The Specimen status mirrors the ServiceRequest/AR status per design.

    :param sr_resource: the ServiceRequest FHIR resource (carries ``_bundle``)
    :param ar_obj: the AnalysisRequest content object
    :param ar_status: HTTP status string used for the AR entry
    :param ar_modified: ISO-formatted last-modified timestamp of the AR
    :returns: list of bundle-response entry dicts, one per specimen
    """
    bundle = sr_resource.get("_bundle")
    if not bundle or not sr_resource.specimen:
        return []

    entries = []
    for spec_ref in sr_resource.specimen:
        specimen = bundle.first_entry("id", str(spec_ref.UUID()))
        if not specimen:
            continue

        # Persist the Specimen dict in the AR's annotation storage and index
        # its UID in the FHIR catalog so search_by_fhir_uid can find the AR.
        fapi.store_fhir_resource(ar_obj, specimen)

        sample_type = SampleTypeFinder(specimen).find()
        if sample_type and ar_obj.getSampleType() != sample_type:
            ar_obj.setSampleType(sample_type)
            ar_obj.reindexObject()

        entries.append({
            "fullUrl": "Specimen/{}".format(specimen.id),
            "response": {
                "status": ar_status,
                "lastModified": ar_modified,
            },
        })

    return entries


@add_route("/<string:resource_type>/<string(length=32):uid>/$revoke",
           ENDPOINT_REVOKE, methods=["POST"])
@add_route("/<string:resource_type>/<string(length=36):uid>/$revoke",
           ENDPOINT_REVOKE, methods=["POST"])
def revoke(context, request, resource_type, uid):
    # disable CSRF
    req.disable_csrf_protection()

    # ensure there is a counterpart object registered for the given uid
    uid = fapi.get_uuid(uid).hex
    obj = api.get_object_by_uid(uid, default=None)
    if not obj:
        fapi.fail("Object not found", status=404)

    # ensure the object found is from the expected type
    implementer = dict(RESOURCE_TYPE_TO_CONTENT).get(resource_type)
    if not implementer:
        fapi.fail("Resource type '%s' is not supported" % resource_type)
    if not implementer.providedBy(obj):
        fapi.fail("Unexpected content type: %s" % api.get_portal_type(obj),
                  status=406)

    # get the FHIR resource that represents the revocation
    resources = get_fhir_resources()
    if not resources:
        fapi.fail("No revocation resource found for '%s'" % resource_type)
    if len(resources) > 1:
        fapi.fail("Revoke with multiple entries is not supported")

    resource = resources[0]
    if not isinstance(resource, ServiceRequestRevocationResource):
        fapi.fail("Not a ServiceRevocationResource")

    # get the reason(s) for rejection/cancellation
    reject_reason = resource.rejection_reason
    reject_allowed = wapi.is_transition_allowed(obj, "reject")
    cancel_allowed = wapi.is_transition_allowed(obj, "cancel")

    if not any([reject_allowed, cancel_allowed]):
        # return a ServiceRequestRevocationError
        request.response.setStatus(403)
        issue = {
            "severity": "error",
            "code": "forbidden",
            "details": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/operation-outcome",  # noqa: E501
                    "code": "MSG_LOCAL_FAIL",
                }],
                "text": "Revoke is not allowed for this resource",
            },
            "expression": ["%s.status" % resource_type],
        }
        return ServiceRequestRevocationError({"issue": [issue]})

    if reject_allowed and not cancel_allowed:
        transition = "reject"
    elif cancel_allowed and not reject_allowed:
        transition = "cancel"
    else:
        # TODO: This is ambiguous when both/neither transitions are allowed;
        # confirm the intended behavior with product/functional owners
        transition = "reject" if reject_reason else "cancel"

    if reject_reason:
        obj.setRejectionReasons(reject_reason)

    success, message = do_action_for(obj, transition)
    if not success:
        # prevent partial commits (e.g. reason was set before transition)
        transaction.abort()
        # return a ServiceRequestRevocationError
        request.response.setStatus(403)
        issue = {
            "severity": "error",
            "code": "forbidden",
            "details": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/operation-outcome",  # noqa: E501
                    "code": "MSG_LOCAL_FAIL",
                }],
                "text": message,
            },
            "expression": ["%s.status" % resource_type],
        }
        return ServiceRequestRevocationError({"issue": [issue]})

    resource = fapi.to_fhir_action_resource(obj, "revoke")
    return resource


def get_specimen_bundle(context, request):
    """Return all Specimens as a FHIR searchset bundle.

    Specimens have no independent SENAITE content type. For ARs created via
    the FHIR bundle API the Specimen is stored as annotation data and returned
    as-is. For ARs created natively in SENAITE (no annotation) a Specimen is
    synthesized on-the-fly from the AR's SampleType and DateSampled so that
    FHIR clients never need to know about SENAITE internals.

    Supports optional ``_lastUpdated`` (e.g. ``gt2026-01-01T00:00:00Z``) to
    filter by the underlying AR's modification date.
    """
    params = request.form
    since = parse_last_updated(params.get("_lastUpdated", ""))
    if isinstance(since, OperationOutcome):
        return since

    query = {"portal_type": "AnalysisRequest"}
    if since:
        query["modified"] = {"query": since, "range": "min"}
    brains = api.search(query)

    entries = []
    for brain in brains:
        ar = api.get_object(brain, default=None)
        if not ar:
            continue
        specimen = fapi.to_fhir_resource(
            ar, resource_type="Specimen", default=None
        )
        if not specimen:
            continue
        entries.append({
            "fullUrl": "Specimen/{}".format(specimen.id),
            "resource": dict(specimen),
            "search": {"mode": "match"},
        })

    bundle_data = {
        "resourceType": "Bundle",
        "id": str(fapi.generate_UUID()),
        "type": "searchset",
        "total": len(entries),
    }
    if entries:
        bundle_data["entry"] = entries

    return ResultsBundleResource(bundle_data)


def get_diagnostic_report_bundle(_context, request):
    """Handle GET /DiagnosticReport with _lastUpdated, _summary, _include.

    Builds a SenaiteResultsBundle (searchset) containing:
      - DiagnosticReport entries with search.mode = "match"
      - Observation entries with search.mode = "include" when
        _include=Observation:result is requested
    """
    params = request.form

    since = parse_last_updated(params.get("_lastUpdated", ""))
    if isinstance(since, OperationOutcome):
        return since
    summary = params.get("_summary", "").lower()

    if summary != "true":
        request.response.setStatus(400)
        issue = {
            "severity": "error",
            "code": "required",
            "details": {
                "text": "_summary=true is required for this endpoint",
            },
            "diagnostics": "This endpoint only supports requests with _summary=true. Include _summary=true as a query parameter.",  # noqa: E501
            "expression": ["_summary"],
        }
        return OperationOutcome({"issue": [issue]})

    is_include_observations = "Observation:result" in params.get("_include", "")  # noqa: E501

    query = {"portal_type": "AnalysisRequest"}
    if since:
        query["modified"] = {"query": since, "range": "min"}
    brains = api.search(query)

    entries = []
    total_match = 0
    seen_obs_uids = set()

    for brain in brains:
        sample = api.get_object(brain, default=None)
        reports = sample.getReports()
        if not reports:
            continue

        # Get the most recent report for this sample
        last_report = reports[-1]
        dr = fapi.to_fhir_resource(last_report, default=None)
        if not dr:
            continue

        total_match += 1

        dr_dict = dict(dr)
        strip_presented_form_data(dr_dict)

        entries.append({
            "fullUrl": "DiagnosticReport/{}".format(dr.id),
            "resource": dr_dict,
            "search": {"mode": "match"},
        })

        if not is_include_observations:
            continue

        for analysis in sample.getAnalyses(full_objects=True):
            if not fapi.is_reportable(analysis):
                continue
            obs_uid = fapi.get_uid(analysis)
            if obs_uid in seen_obs_uids:
                continue
            seen_obs_uids.add(obs_uid)

            obs = fapi.to_fhir_resource(analysis, default=None)
            if not obs:
                continue

            entries.append({
                "fullUrl": "Observation/{}".format(obs.id),
                "resource": dict(obs),
                "search": {"mode": "include"},
            })

    now = dtime.to_localized_time(dtime.now(), long_format=True)
    bundle_data = {
        "resourceType": "Bundle",
        "id": str(fapi.generate_UUID()),
        "meta": {
            "profile": [to_fhir_profile_url("SenaiteResultsBundle")],
        },
        "type": "searchset",
        "timestamp": now,
        "total": total_match,
    }

    if entries:
        bundle_data["entry"] = entries

    return ResultsBundleResource(bundle_data)


def parse_last_updated(value):
    """Parse a FHIR _lastUpdated value into a catalog min-range boundary
    """
    if not value:
        return None

    if value.startswith("gt"):
        value = value[2:]

    since = dtime.to_DT(value)
    if not since:
        request = req.get_request()
        request.response.setStatus(400)
        issue = {
            "severity": "error",
            "code": "invalid",
            "details": {
                "text": "Malformed _lastUpdated value",
            },
            "diagnostics": "_lastUpdated must be a valid FHIR instant, for example gt2026-05-28T00:00:00Z.",  # noqa: E501
            "expression": ["_lastUpdated"],
        }
        return OperationOutcome({"issue": [issue]})

    return since


def strip_presented_form_data(dr_dict):
    """Remove the base64 PDF payload from presentedForm
    """
    for attachment in dr_dict.get("presentedForm") or []:
        attachment.pop("data", None)


def get_fhir_resources():
    """Returns the resources from the request
    """
    resources = []

    # get the FHIR raw records
    records = req.get_request_data()
    for record in records:
        # convert to a FHIR resource
        resource = fapi.to_fhir_resource(record)

        # if the resource is a Bundle, extract all contained resources
        if IBundleResource.providedBy(resource):
            for entry in resource.entry:
                # convert each entry to a FHIR resource
                entry_res = fapi.to_fhir_resource(entry)
                if not entry_res:
                    continue
                # assign the bundle so we can resolve references
                # TODO this '_bundle' dance is a bit ugly
                entry_res["_bundle"] = resource
                # add to the resources list
                resources.append(entry_res)

        # append the resource
        resources.append(resource)

    return resources
