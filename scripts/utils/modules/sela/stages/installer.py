from abc import ABC, abstractmethod

from modules.sela.definitions import Filename


class Installer(ABC):
    """
    Responsible for installing specific assets.
    """

    @abstractmethod
    def install(self, files: list[Filename]) -> None:
        raise NotImplementedError


class MoveInstaller(Installer):
    """
    Default class that will, by default, move the src list of files, to dest, overwriting them.
    """
    def __init__(self, dest: Filename):
        self.dest = dest

    def install(self, src: list[Filename]) -> None:
        raise NotImplementedError  # TODO
