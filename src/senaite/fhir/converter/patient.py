# -*- coding: utf-8 -*-

from bika.lims import api
from senaite.core.api import dtime
from senaite.fhir import api as fapi
from senaite.fhir.converter import group_by
from senaite.fhir.converter import to_content_address
from senaite.fhir.converter import to_fhir_datetime
from senaite.fhir.converter import to_fhir_identifier as to_fhir_id
from senaite.fhir.converter import to_fhir_profile_url
from senaite.fhir.interfaces import IContentToFHIR
from senaite.fhir.interfaces import IFHIRToContent
from senaite.fhir.interfaces import IPatientResource
from senaite.fhir.resource.patient import PatientResource
from senaite.patient.config import GENDERS
from senaite.patient.config import SEXES
from senaite.patient.interfaces import IPatient
from zope.component import adapter
from zope.interface import implementer


# senaite.patient gender key -> FHIR R5 administrative-gender code
# https://hl7.org/fhir/R5/valueset-administrative-gender.html
#
# TODO Lossy mapping: FHIR administrative-gender has no distinction between
# transgender and diverse, so both "t" and "d" collapse to "other". A
# round-trip Patient("t") -> FHIR("other") -> Patient("d") loses the original
# value (see ResourceToPatient.get_gender below, which maps "other" back to
# "d"). Carrying the SENAITE-specific identity in a dedicated extension
# (e.g. patient-genderIdentity) would preserve it across conversions.
GENDER_TO_FHIR = {
    "m": "male",
    "f": "female",
    "t": "other",
    "d": "other",
    "": "unknown",
}


@adapter(IPatient)
@implementer(IContentToFHIR)
class PatientToResource(object):

    def __init__(self, patient):
        self.patient = patient

    def get_fhir_identifiers(self):
        # basic identifiers
        identifiers = [
            to_fhir_id("context", self.patient.getId(), use="usual"),
            to_fhir_id("mrn", self.patient.getMRN(), use="official")
        ]
        # secondary identifiers
        for key, value in self.patient.get_identifier_items():
            sys_id = fapi.slugify(key)
            fhir_id = to_fhir_id(sys_id, value, use="secondary")
            identifiers.append(fhir_id)
        # remove empties
        return list(filter(None, identifiers))

    def to_fhir_resource(self):
        modified = api.get_modification_date(self.patient)
        modified = to_fhir_datetime(modified)
        uuid = fapi.get_uuid(self.patient)
        profile_url = to_fhir_profile_url("Patient")
        data = {
            "resourceType": "Patient",
            "id": str(uuid),
            "status": api.get_review_status(self.patient),
            "meta": {
                "profile": [profile_url],
                "lastUpdated": modified,
            },
            "identifier": self.get_fhir_identifiers(),
        }

        given = [self.patient.getFirstname(), self.patient.getMiddlename()]
        data["name"] = {
            "family": self.patient.getLastname(),
            "given": list(filter(None, given)),
            "use": "official",
        }

        dob = self.patient.getBirthdate()
        data["birthDate"] = dtime.date_to_string(dob)

        gender = self.patient.getGender() or ""
        data["gender"] = GENDER_TO_FHIR.get(gender, "unknown")

        return PatientResource(data)


@adapter(IPatientResource)
@implementer(IFHIRToContent)
class ResourceToPatient(object):

    def __init__(self, resource):
        self.resource = resource

    def to_content_dict(self):
        # Medical Record Number
        mrn = self.get_mrn()
        if not mrn:
            # TODO check whether mrn is required in current instance
            raise ValueError("%r: No MRN" % self.resource)

        # Patient name
        firstname = self.get_firstname()
        middlename = self.get_middlename()
        lastname = self.get_lastname()
        if not any([firstname, lastname]):
            raise ValueError("%r: No valid name" % self.resource)

        # Sex and gender
        sex = self.get_sex()
        gender = self.get_gender()

        # Date of birth
        birthdate = self.get_birthdate()
        estimated = self.get_estimated_birthdate()

        # Address
        address = self.get_address()

        # Marital status
        marital = self.get_marital_status()

        # Email(s)
        primary_email = self.get_primary_email()
        additional_emails = self.get_additional_emails()

        # Phone(s)
        primary_phone = self.get_primary_phone()
        additional_phones = self.get_additional_phones()

        # Container path
        portal = api.get_portal()
        parent_path = "%s/patients" % api.get_path(portal)

        return {
            "portal_type": "Patient",
            "parent_path": parent_path,
            "mrn": api.safe_unicode(mrn),
            "sex": api.safe_unicode(sex),
            "gender": api.safe_unicode(gender),
            "birthdate": birthdate,
            "estimated_birthdate": estimated,
            "address": list(filter(None, [address])),
            "firstname": api.safe_unicode(firstname),
            "middlename": api.safe_unicode(middlename),
            "lastname": api.safe_unicode(lastname),
            "marital": api.safe_unicode(marital),
            "email": api.safe_unicode(primary_email),
            "additional_emails": additional_emails,
            "phone": api.safe_unicode(primary_phone),
            "additional_phones": additional_phones,
        }

    def get_mrn(self):
        """Returns the MRN from the resource
        """
        identifier = self.resource.get_identifier(use="secondary")
        return identifier.value if identifier else None

    def get_sex(self):
        """Returns the Sex from the resource, suitable for Patient content type
        """
        # supported genders: male | female | other | unknown
        # https://fhir.senaite.org/StructureDefinition-SenaitePatient-definitions.html#Patient.gender
        gender = self.resource.gender
        if not gender:
            return ""
        sexes = dict(SEXES).keys()
        key = gender[0].lower()
        if key in sexes:
            return key
        return ""

    def get_gender(self):
        # supported genders: male | female | other | unknown
        # https://fhir.senaite.org/StructureDefinition-SenaitePatient-definitions.html#Patient.gender
        gender = self.resource.gender
        if not gender:
            return ""
        # other --> diverse
        gender = "d" if gender == "other" else gender
        genders = dict(GENDERS).keys()
        key = gender[0].lower()
        if key in genders:
            return key
        return ""

    def get_human_name(self):
        """Returns a dict that represents the name of the Patient
        """
        human_name = self.resource.get_name(use="official")
        if human_name:
            return human_name

        # no official name, pick the first one
        human_name = self.resource.name
        return human_name[0] if human_name else None

    def get_firstname(self):
        name = self.get_human_name()
        given = name.given
        return given[0] if given else ""

    def get_middlename(self):
        name = self.get_human_name()
        given = name.given
        return given[1] if len(given) > 1 else ""

    def get_lastname(self):
        name = self.get_human_name()
        return name.family if name else ""

    def get_birthdate(self):
        return self.resource.birthDate

    def get_estimated_birthdate(self):
        """Returns whether the birthdate from the patient resource is
        considered estimated or not
        """
        return self.resource.estimatedDateBirth

    def get_address_element(self):
        """Returns the address of this patient, giving priority to home
        address first
        """
        priority = ["home", "work", "temp", "old"]
        address = None
        for use in priority:
            address = self.resource.get_address(use)
            if address:
                break
        return address

    def get_address(self):
        """Returns a content dict representation of the resource address
        """
        address = self.get_address_element()
        return to_content_address(address)

    def get_marital_status(self, default="UNK"):
        status = self.resource.maritalStatus
        status = status.coding if status else None
        status = status[0] if status else None
        if not status:
            return default

        code = status.code or ""
        display = status.display or ""
        if not any([code, display]):
            return default

        # get the marital statuses registered in the system
        reg_key = "senaite.patient.marital_statuses"
        supported = api.get_registry_record(reg_key)

        # find out if there is a match
        for status in supported:
            key = status.get("key")
            name = status.get("value")
            if code.lower() in [key.lower(), name.lower()]:
                return key
            if display.lower() in [key.lower(), name.lower()]:
                return key

        # return default
        return default

    def get_email_elements(self):
        # get all emails of this patient
        telecom = self.resource.telecom
        grouped = group_by(telecom, key="system")
        return grouped.get("email") or []

    def get_primary_email(self):
        """Returns the primary email address
        """
        emails = self.get_email_elements()
        grouped = group_by(emails, key="use")
        element = grouped.get("home")
        if not element:
            element = grouped.get("work")
        return element[0].value if element else None

    def get_additional_emails(self):
        emails = []
        for email in self.get_email_elements():
            emails.append({
                u"name": api.safe_unicode(email.use),
                u"email": api.safe_unicode(email.value)
            })
        return emails

    def get_phone_elements(self):
        # get all phones of this patient
        telecom = self.resource.telecom
        grouped = group_by(telecom, key="system")
        return grouped.get("phone") or []

    def get_primary_phone(self):
        """Returns the primary email address
        """
        phones = self.get_phone_elements()
        grouped = group_by(phones, key="use")
        element = grouped.get("home")
        if not element:
            element = grouped.get("work")
        return element[0].value if element else None

    def get_additional_phones(self):
        phones = []
        for phone in self.get_phone_elements():
            phones.append({
                u"name": api.safe_unicode(phone.use),
                u"phone": api.safe_unicode(phone.value)
            })
        return phones
