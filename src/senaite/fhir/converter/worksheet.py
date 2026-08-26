# -*- coding: utf-8 -*-

from bika.lims import api
from senaite.core.interfaces import IWorksheet
from senaite.fhir import api as fapi
from senaite.fhir.config import WORKSHEET_TASK_STATUSES
from senaite.fhir.config import WORKSHEET_CAPACITY_EXTENSION
from senaite.fhir.converter import to_fhir_datetime
from senaite.fhir.converter import to_fhir_identifier
from senaite.fhir.converter import to_fhir_profile_url
from senaite.fhir.interfaces import IContentToFHIR
from senaite.fhir.monkeys.content.analysis import link_instrument_service_request  # noqa: E501
from senaite.fhir.resource.task import TaskResource
from zope.component import adapter
from zope.component import queryAdapter
from zope.interface import implementer


@adapter(IWorksheet)
@implementer(IContentToFHIR)
class WorksheetToTask(object):
    """Convert an eligible Worksheet to a SenaiteWorksheetTask
    """

    def __init__(self, worksheet):
        self.worksheet = worksheet

    def to_fhir_resource(self):
        analyses, instrument = self.get_task_assignment()
        if not analyses or not instrument:
            return None

        status = self.get_status()
        if not status:
            return None

        uid = self.get_or_create_task_uid()
        data = {
            "resourceType": "Task",
            "id": str(fapi.get_uuid(uid)),
            "meta": {
                "profile": [to_fhir_profile_url("SenaiteWorksheetTask")],
                "lastUpdated": to_fhir_datetime(
                    api.get_modification_date(self.worksheet)),
            },
            "text": self.get_narrative(uid, status, analyses, instrument),
            "extension": self.get_extensions(),
            "identifier": [
                to_fhir_identifier(
                    "worksheet-id", api.get_id(self.worksheet), use="usual")
            ],
            "intent": "order",
            "status": status,
            "code": {
                "text": "Laboratory Worksheet",
            },
            "requestedPerformer": [{
                "reference": "Device/{}".format(fapi.get_fhir_id(instrument))
            }],
            "authoredOn": to_fhir_datetime(
                api.get_creation_date(self.worksheet)),
            "input": self.get_inputs(analyses),
        }
        return TaskResource(data)

    def get_task_assignment(self):
        """Return the analyses and their one shared instrument, if any
        """
        analyses = list(self.worksheet.getAnalyses() or [])
        if not analyses:
            return [], None

        instruments = []
        for analysis in analyses:
            instrument = analysis.getInstrument()
            if not instrument:
                return [], None
            instruments.append(instrument)

        uids = set([api.get_uid(i) for i in instruments])
        if len(uids) != 1:
            return [], None
        return analyses, instruments[0]

    def get_or_create_task_uid(self):
        """Give an eligible worksheet one stable Task identity
        """
        uid = fapi.get_fhir_uid(self.worksheet, "Task")
        if uid:
            return uid
        uid = fapi.generate_UUID().hex
        fapi.set_fhir_uids(self.worksheet, Task=uid)
        return uid

    def get_status(self):
        return dict(WORKSHEET_TASK_STATUSES).get(
            api.get_review_status(self.worksheet))

    def get_extensions(self):
        return [{
            "url": WORKSHEET_CAPACITY_EXTENSION,
            "valuePositiveInt": self.get_capacity(),
        }]

    def get_capacity(self):
        template = self.worksheet.getWorksheetTemplate()
        return template.getNumOfPositions() if template else 0

    def get_narrative(self, uid, status, analyses, instrument):
        """Build a human-readable XHTML representation of the Task
        """
        task_id = str(fapi.get_uuid(uid))
        worksheet_id = api.safe_unicode(api.get_id(self.worksheet))
        capacity = self.get_capacity()
        authored_on = to_fhir_datetime(api.get_creation_date(self.worksheet))
        device_id = fapi.get_fhir_id(instrument)
        device_title = api.safe_unicode(api.get_title(instrument))
        status_title = status.replace("-", "").upper()
        profile = (
            '<div style="display: inline-block; background-color: #d9e0e7; '
            'padding: 6px; margin: 4px; border: 1px solid #8da1b4; '
            'border-radius: 5px; line-height: 60%">'
            '<p style="margin-bottom: 0px"></p>'
            '<p style="margin-bottom: 0px">Profile: '
            '<a href="StructureDefinition-SenaiteWorksheetTask.html">'
            'Senaite Worksheet Task</a></p></div>')
        performer = (
            '<h3>RequestedPerformers</h3><table class="grid">'
            '<tr><td style="display: none">-</td><td><b>Reference</b></td>'
            '</tr><tr><td style="display: none">*</td><td>'
            '<a href="Device-{0}.html">Device: displayName = {1}</a>'
            '</td></tr></table>').format(device_id, device_title)
        return {
            "status": "generated",
            "div": u'<div xmlns="http://www.w3.org/1999/xhtml">'
                   u'<p class="res-header-id"><b>Generated Narrative: '
                   u'Task {task_id}</b></p><a name="{task_id}"> </a>'
                   u'<a name="hc{task_id}"> </a>{profile}'
                   u'<p><b>Worksheet Capacity</b>: {capacity}</p>'
                   u'<p><b>identifier</b>: {worksheet_id} '
                   u'(use: usual)</p><p><b>status</b>: {status}</p>'
                   u'<p><b>intent</b>: order</p><p><b>code</b>: '
                   u'<span title="Codes:">Laboratory Worksheet</span></p>'
                   u'<p><b>authoredOn</b>: {authored_on}</p>{performer}{inputs}'  # noqa: E501
                   u'</div>'.format(
                       task_id=task_id,
                       profile=profile,
                       capacity=capacity,
                       worksheet_id=worksheet_id,
                       status=status_title,
                       authored_on=authored_on,
                       performer=performer,
                       inputs=self.get_narrative_inputs(analyses)),
        }

    def get_narrative_inputs(self, analyses):
        inputs = []
        for item in self.get_inputs(analyses):
            reference = item["valueReference"]["reference"]
            resource_id = reference.split("/", 1)[-1]
            inputs.append(
                '<blockquote><p><b>input</b></p><p><b>type</b>: '
                '<span title="Codes:{{http://hl7.org/fhir/fhir-types '
                'ServiceRequest}}">ServiceRequest</span></p><p><b>value</b>: '
                '<a href="ServiceRequest-{0}.html">{1}</a></p></blockquote>'.format(  # noqa: E501
                    resource_id, reference))

        return "".join(inputs)

    def get_inputs(self, analyses):
        inputs = []
        for analysis in analyses:
            service_request = queryAdapter(
                analysis, IContentToFHIR, name="ServiceRequest")

            if not service_request:
                continue

            resource = service_request.to_fhir_resource()
            if not resource:
                # Analyses assigned before senaite.fhir was installed do not
                # yet carry the instrument ServiceRequest identity. Create it
                # now so every worksheet analysis is represented in Task.input.
                link_instrument_service_request(analysis)
                resource = service_request.to_fhir_resource()

            if not resource:
                continue

            inputs.append({
                "type": {"coding": [{
                    "system": "http://hl7.org/fhir/fhir-types",
                    "code": "ServiceRequest",
                }]},
                "valueReference": {
                    "reference": "ServiceRequest/{}".format(resource.id),
                },
            })

        return inputs
