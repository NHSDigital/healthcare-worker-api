from abc import abstractmethod


class FhirObject:
    @abstractmethod
    def to_json(self):
        pass
