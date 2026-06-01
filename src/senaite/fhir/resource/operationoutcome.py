# -*- coding: utf-8 -*-

from senaite.fhir import api as fapi
from senaite.fhir.datatype.codeableconcept import CodeableConcept
from senaite.fhir.resource import FHIRResource


class OperationOutcome(FHIRResource):

    __cardinality = (
        ("issue", "1..*"),
    )

    def _initialize(self):
        super(OperationOutcome, self)._initialize()
        self["resourceType"] = "OperationOutcome"
        self["id"] = str(fapi.generate_UUID())

    @property
    def issue(self):
        """An error, warning, or information message that results from a system
        action.
        https://hl7.org/fhir/R5/operationoutcome-definitions.html#OperationOutcome.issue
        """
        records = self.get("issue") or []
        return [OperationOutcomeIssue(record) for record in records]


class OperationOutcomeIssue(FHIRResource):

    __cardinality = (
        ("severity", "1..1"),
        ("code", "1..1"),
        ("details", "0..1"),
        ("diagnostics", "0..1"),
        ("expression", "0..*"),
    )

    @property
    def severity(self):
        """Indicates whether the issue indicates a variation from successful
        processing
        Value set: fatal | error | warning | information | success
        https://www.hl7.org/fhir/R5/operationoutcome-definitions.html#OperationOutcome.issue.severity
        """
        return self.get("severity")

    @property
    def code(self):
        """Describes the type of the issue. The system that creates an
        OperationOutcome SHALL choose the most applicable code from the
        IssueType value set, and may additional provide its own code for the
        error in the details element.
        https://www.hl7.org/fhir/R5/operationoutcome-definitions.html#OperationOutcome.issue.code
        """
        return self.get("code")

    @property
    def details(self):
        """Additional details about the error. This may be a text description
        of the error or a system code that identifies the error.
        https://www.hl7.org/fhir/R5/operationoutcome-definitions.html#OperationOutcome.issue.details
        """
        data = self.get("details")
        return CodeableConcept(data) if data else None

    @property
    def diagnostics(self):
        """Additional diagnostic information about the issue.
        https://www.hl7.org/fhir/R5/operationoutcome-definitions.html#OperationOutcome.issue.diagnostics
        """
        return self.get("diagnostics")

    @property
    def expression(self):
        """A simple subset of FHIRPath limited to element names, repetition
        indicators and the default child accessor that identifies one of the
        elements in the resource that caused this issue to be raised
        https://www.hl7.org/fhir/R5/operationoutcome-definitions.html#OperationOutcome.issue.expression
        """
        return self.get("expression") or []
