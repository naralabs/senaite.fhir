# -*- coding: utf-8 -*-

from senaite.jsonapi.exceptions import APIError


class FHIRAPIError(APIError):
    """Exception Class for FHIR's API Errors
    """


class ServiceRequestValidationError(Exception):
    """Raised when a ServiceRequest violates validation rules
    """

    def __init__(self, message, expression=None, code="business-rule"):
        super(ServiceRequestValidationError, self).__init__(message)
        self.expression = expression or []
        self.code = code


class ObservationValidationError(Exception):
    """Raised when an Observation violates validation rules
    """

    def __init__(self, message, expression=None, code="business-rule"):
        super(ObservationValidationError, self).__init__(message)
        self.expression = expression or []
        self.code = code
