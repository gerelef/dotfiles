from abc import ABC, abstractmethod
from pathlib import Path


class Janitor(ABC):
    """
    Responsible for cleaning up remaining assets.
    """

    @abstractmethod
    def cleanup(self, files: list[Path]) -> None:
        """
        :param files: List of files to clean up, which may or may not exist.
        """
        raise NotImplementedError


class SloppyJanitor(Janitor):
    """
    Default class that will, by default, clean up nothing (hence the name).
    """
    def cleanup(self, files: list[Path]) -> None:
        return
