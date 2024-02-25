from abc import ABC, abstractmethod
from pathlib import Path
from typing import override


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

    @override
    def cleanup(self, files: list[Path]) -> None:
        return


class PunctualJanitor(Janitor):
    """
    Default class that will, by default, clean up everything.
    """

    @override
    def cleanup(self, files: list[Path]) -> None:
        for p in files:
            if p.exists():
                p.unlink(missing_ok=True)
