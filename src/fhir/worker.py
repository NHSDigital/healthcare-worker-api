import json

from fhir.fhir_object import FhirObject


class RoleProfile(FhirObject):
    id: str
    roleName: str
    roleCode: str

    def to_json(self):
        return json.dumps({"id": id})


class OrgPerson(FhirObject):
    id: str
    dateOpened: str
    orgName: str
    orgId: str
    roleProfiles: [RoleProfile]

    def to_json(self):
        return json.dumps({"id": id})


class FhirWorker(FhirObject):
    id: str
    forename: str
    middlenames: str
    surname: str
    initials: str
    title: str
    orgPersons: [OrgPerson]

    def to_json(self):
        return json.dumps({"id": self.id})
