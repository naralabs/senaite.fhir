# -*- coding: utf-8 -*-

import json
import time

from senaite.fhir.resource.operationoutcome import OperationOutcome
from senaite.jsonapi import api as jsonapi


def require_authentication(func):
    """Rejects unauthenticated FHIR requests with a FHIR error response

    Meant to wrap the view's `__call__`, which is its single entry point:
    `publishTraverse` appends every path segment to the traversal subpath and
    returns the view itself, so the representation methods (`to_json`,
    `to_xml`, `to_binary_stream`) are never reached through traversal.

    Gating there rather than on each of them keeps one check for every
    representation, and lets the rejection be rendered as the FHIR JSON
    `OperationOutcome` the spec asks for. The `returns_binary_stream` and
    `returns_xml` wrappers cannot render one: the former feeds whatever it
    gets to `os.path.getsize`, the latter runs it through `dicttoxml`, which
    does not produce FHIR XML.
    """
    def decorator(*args, **kwargs):
        instance = args[0]
        request = instance.request

        if not jsonapi.is_anonymous():
            return func(*args, **kwargs)

        request.response.setStatus(401)
        request.response.setHeader("WWW-Authenticate", "Bearer")
        request.response.setHeader("Content-Type", "application/json")

        # Serialized here, rather than returned for `returns_json` to render,
        # because this wraps `__call__`: there is no wrapper left outside
        outcome = OperationOutcome({
            "issue": [{
                "severity": "error",
                "code": "security",
                "diagnostics": "Invalid or expired authentication token",
            }],
        })
        return json.dumps(outcome)

    return decorator


def runtime(func):
    """Measures the runtime of the wrapped route handler.

    Unlike plone.jsonapi.core's ``runtime`` decorator, which injects a
    non-FHIR ``_runtime`` key into the response body, this reports the
    elapsed time through the W3C ``Server-Timing`` response header so the
    payload remains valid FHIR:

        Server-Timing: senaite;dur=142

    The ``dur`` value is expressed in milliseconds, as per the spec.

    https://www.w3.org/TR/server-timing/
    """

    def decorator(*args, **kwargs):
        instance = args[0]
        request = getattr(instance, "request", None)
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        if request is not None:
            # Server-Timing duration is expressed in milliseconds
            duration = (end - start) * 1000
            request.response.setHeader(
                "Server-Timing", "senaite;dur=%s" % round(duration, 1))
        return result

    return decorator
