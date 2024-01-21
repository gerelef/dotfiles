import os
import shutil
from abc import ABC, abstractmethod

from modules.sela.definitions import Filename
from modules.sela.stages.logger import Logger


class Installer(ABC):
    """
    Responsible for installing specific assets.
    """

    @abstractmethod
    def install(self, files: list[Filename]) -> None:
        """
        This operation may have side effects; installation might require creating auxiliary files.
        :param files: Files to install. This list will be appropriately appended for auxiliary files.
        :raises InstallationFailed: raised when installation failed
        """
        raise NotImplementedError


class CopyInstaller(Installer):
    """
    Default class that will, by default, copy the src list of files, to dest.
    """
    def __init__(self, logger: Logger, dest: Filename):
        self.logger = logger
        self.dest = dest

    def install(self, src: list[Filename]) -> None:
        self.logger.log_progress("Installing ")
        if not os.path.exists(self.dest):
            os.makedirs(self.dest)

        for file in src:
            shutil.copy2(file, self.dest)
