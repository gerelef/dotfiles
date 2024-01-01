from abc import abstractmethod
from typing import Iterator, Callable

from modules.sela import exceptions
from modules.sela.definitions import URL
from modules.sela.status import HTTPStatus
from modules.sela.releases.abstract import Release

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
    def download(self, url: URL, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        """
        Downloads a packet of size chunk_size from URL, which belongs to the provider defined previously.
        Generator that returns a binary data packet of size chunk_size, iteratively requested from url.
        :param url: URL to download content from.
        :param chunk_size: max chunk size to download per iteration
        :returns: Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        raise NotImplementedError

    def get_release(self, fltr: Filter) -> tuple[HTTPStatus, Release | None]:
        """
        :param fltr: filter to use in order to match the correct release
        :raises exceptions.NoReleaseFound:
        :raises requests.exceptions.JSONDecodeError:
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        status: HTTPStatus
        release: Release
        for status, release in self.recurse_releases():
            if not status.is_successful():
                return status, None
            if release is None:
                continue
            if fltr(release):
                return status, release

        raise exceptions.NoReleaseFound("No release found, or matched!")

    @staticmethod
    @abstractmethod
    def match(u: URL) -> bool:
        """
        Matches whether a url is supported by this specific Provider concrete implementation.
        :param u: URL to match.
        :returns: True if this url is supported.
        """
        raise NotImplementedError
