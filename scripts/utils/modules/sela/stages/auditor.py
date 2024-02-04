from abc import ABC, abstractmethod
from pathlib import Path


class Auditor(ABC):
    """
    Responsible for verifying the integrity of the files of a given release.
    """

    @abstractmethod
    def verify(self, files: list[Path]) -> None:
        """
        :raises FileVerificationFailed: if the verification fails, raise this exception
        """
        # no repository supports checksums
        raise NotImplementedError


class NullAuditor(Auditor):
    """
    Default class that will, by default, skip any possible checksum inspection.
    """
    def verify(self, files: list[Path]) -> None:
        pass  # do nothing
