from abc import ABC, abstractmethod

from modules.sela.definitions import Filename


class Janitor(ABC):
    """
    Responsible for cleaning up remaining assets.
    """

    @abstractmethod
    def cleanup(self, files: list[Filename]) -> None:
        raise NotImplementedError


class SloppyJanitor(Janitor):
    """
    Default class that will, by default, clean up nothing (hence the name).
    """
    def cleanup(self, files: list[Filename]) -> None:
        return
