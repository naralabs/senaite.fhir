# -*- coding: utf-8 -*-

import time


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
