from abc import abstractmethod
from typing import Iterator, Callable

from modules.sela.sela.definitions import URL, HTTPStatus
from modules.sela.sela.releases.release import Release

type Filter = Callable[[Release], bool]


class Provider:
    """
    Wrapper/Facade for Git API endpoints.
    Use by instantiating with ProviderFactory and using get_release(f: Filter)
    """

    def __init__(self, url: URL):
        """
        :param url: git project endpoint to use
        :raises Exceptions.UnknownProviderException:
        raised if the repository provider is not supported
        """
        self.repository = url

    @abstractmethod
    def recurse_releases(self) -> Iterator[tuple[HTTPStatus, Release | None]]:
        """
        Generator to get all GitHub releases for a given project.
        :returns: Iterator[tuple[HTTPStatus, Release | None]]:
        :raises requests.exceptions.JSONDecodeError: Raised if unable to decode Json due to mangled data
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        raise NotImplementedError

    @abstractmethod
    def download(self, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        """
        Downloads a packet of size chunk_size from URL, which belongs to the provider defined previously.
        Generator that returns a binary data packet of size chunk_size, iteratively requested from url.
        :returns: Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        raise NotImplementedError

    def get_release(self, f: Filter) -> Release | None:
        """
        :param f: filter to use in order to match the correct release
        :returns Release | None:
        :raises requests.exceptions.JSONDecodeError:
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        status: HTTPStatus
        release: Release
        for status, release in self.recurse_releases():
            if status == HTTPStatus.CLIENT_ERROR or status == HTTPStatus.SERVER_ERROR:
                return None
            if release is None:
                continue
            if f(release):
                return release
