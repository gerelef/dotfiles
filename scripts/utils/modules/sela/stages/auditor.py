from abc import ABC, abstractmethod
from modules.sela.definitions import Filename


class Auditor(ABC):
    """
    Responsible for verifying the integrity of the files of a given release.
    """

    @abstractmethod
    def verify(self, files: list[Filename]) -> None:
        """
        :raises FileVerificationFailed: if the verification fails, raise this exception
        """
        # no repository supports checksums
        raise NotImplementedError


class NullAuditor(Auditor):
    """
    Default class that will, by default, skip any possible checksum inspection.
    """
    def verify(self, files: list[Filename]) -> None:
        pass  # do nothing
