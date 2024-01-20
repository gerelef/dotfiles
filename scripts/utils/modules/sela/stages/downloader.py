from abc import ABC, abstractmethod

from modules.sela.definitions import Filename, URL


class Downloader(ABC):
    """
    Responsible for downloading a release.
    """

    @abstractmethod
    def download(self, to_download_dict: dict[Filename, URL]) -> list[Filename]:
        raise NotImplementedError


class DefaultDownloader(Downloader):
    """
    Default class that will, by default, download the dict of files
    and return the path towards the downloaded elements.
    """
    def download(self, to_download_dict: dict[Filename, URL]) -> list[Filename]:
        raise NotImplementedError  # TODO
