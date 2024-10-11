from abc import abstractmethod


class FhirObject:
    """
    Base Fhir Object class which all others inherit from. These are what are returned in the lambda response to
    be returned to the user. All objects must implement their own serialise method in the to_json function.
    """
    @abstractmethod
    def to_json(self) -> str:
        """
        Each implementation of the abstract FhirObject class are responsible for their own serialisation, this
        includes triggering the serialisation of child objects.
        :return: Serialised object representation (as json)
        """
        pass
