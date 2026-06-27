# -*- coding: utf-8 -*-

from senaite.jsonapi.exceptions import APIError


class FHIRAPIError(APIError):
    """Exception Class for FHIR's API Errors
    """


class ServiceRequestValidationError(Exception):
    """Raised when a ServiceRequest violates validation rules
    """

    def __init__(self, message, expression=None):
        super(ServiceRequestValidationError, self).__init__(message)
        self.expression = expression or []
