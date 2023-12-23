import enum
import os
from abc import ABC, abstractmethod
from typing import Callable

from modules.sela import exceptions
from modules.sela.definitions import Filename, URL
from modules.sela.status import HTTPStatus
from modules.sela.exceptions import UnsuccessfulRequest
from modules.sela.factories.abstract import ProviderFactory
from modules.sela.factories.github import GitHubProviderFactory
from modules.sela.helpers import auto_str
from modules.sela.releases.abstract import Release


@auto_str
class Manager(ABC):
    # FIXME add documentation
    # If you're going to be overriding functions using any of the functions below, this will be an important need
    # https://stackoverflow.com/questions/23082509/how-is-the-self-argument-magically-passed-to-instance-methods
    # https://stackoverflow.com/questions/1015307/how-to-bind-an-unbound-method-without-calling-it
    LOG_NOTHING: Callable[[object, str], None] = lambda _, s: None
    VERIFY_NOTHING: Callable[[object, list[Filename]], bool] = lambda _, f: True
    FILTER_FIRST: Callable[[object, Release], bool] = lambda _, r: True
    DO_NOTHING: Callable[[object, list[Filename]], bool] = lambda _, f: None

    class Level(enum.IntEnum):
        ERROR = 32
        WARNING = 16
        DEBUG = 8
        INFO = 4
        PROGRESS_BAR = 2
        PROGRESS = 1

    def __init__(self, repository: URL, temp_dir: Filename, factory_cls: type[ProviderFactory] = GitHubProviderFactory):
        """
        :param repository: direct URL to the repository to make requests
        :param temp_dir: temporary download directory path
        :raises FileNotFoundError: raised if download_dir doesn't exist, or not enough permissions to execute os.stat(d)
        """
        self.repository = repository
        self.provider = factory_cls(repository).create()

        self.download_dir = temp_dir
        if not os.path.exists(self.download_dir):
            raise FileNotFoundError(
                f"Couldn't find, or not enough permissions to use os.stat(), on {self.download_dir}"
            )

    def run(self) -> None:
        """
        :raises UnsuccessfulRequest: raised when a critical request errored
        :raises exceptions.NoReleaseFound: raised when no release matched
        :raises exceptions.NoAssetsFound: raised when no assets are available/returned
        :raises exceptions.FileVerificationFailed: raised when file verification failed
        :raises requests.JSONDecodeError: raised when there's malformed JSON in the response
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        files: list[Filename] = []
        self.log(Manager.Level.PROGRESS, "Starting preprocessing...")
        try:
            status, r = self.provider.get_release(self.filter)
            if not status.is_successful():
                raise UnsuccessfulRequest("Couldn't get release from remote!", status)

            downloadables = self.get_assets(r)
            if not downloadables:
                raise exceptions.NoAssetsFound("No assets found, or matched! Is everything OK?")

            self.log(Manager.Level.PROGRESS, "Starting downloads...")
            for fn, url in downloadables.items():
                files.append(fn)
                self.log(Manager.Level.PROGRESS, f"Downloading {fn}")
                status = self.download(os.path.join(self.download_dir, fn), url)
                if not status.is_successful():
                    raise UnsuccessfulRequest(f"Couldn't download asset at url {url}", status)

            self.log(Manager.Level.PROGRESS, "Verifying...")
            if not self.verify(files):
                raise exceptions.FileVerificationFailed("Couldn't verify files!")

            self.log(Manager.Level.PROGRESS, "Installing...")
            self.install(files)
        finally:
            self.cleanup(files)

    @abstractmethod
    def filter(self, release: Release) -> bool:
        """
        Check if this is the release we want to download.
        Note: if you just need the latest available release, override with FILTER_FIRST!
        Remember to bind the function to your instance with types.MethodType(FILTER_FIRST, instance)
        :param release:
        :returns bool: True if attributes match what we want to download, false otherwise.
        """
        raise NotImplementedError

    @abstractmethod
    def get_assets(self, r: Release) -> dict[Filename, URL]:
        """
        Get the assets that we'll download from a specific Release.
        :returns dict[Filename, URL]: a dict where filenames match the URL we'll download from
        """
        raise NotImplementedError

    def download(self, filename: Filename, url: URL) -> HTTPStatus:
        """
        Downloads a specific file fromn url, stored in directory + filename.
        Finishes early upon HTTPStatus error.
        :param filename: absolute path to the filename we're going to write
        :param url: url to download from
        :return: last HTTPStatus received by self.provider.download
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        kilobytes_denominator = 1_000_000
        with open(filename, "wb") as out:
            for status, bread, btotal, data in self.provider.download(url):
                if not status.is_successful():
                    return status

                self.log(
                    Manager.Level.PROGRESS_BAR,
                    f"\r{round(bread / kilobytes_denominator)}"
                    f"/{round(btotal / kilobytes_denominator)} MB "
                    f"| {round((bread / btotal) * 100, 1)}% | {filename}"
                )

                out.write(data)
            self.log(Manager.Level.PROGRESS_BAR, f"\n")
            return status

    @abstractmethod
    def verify(self, files: list[Filename]) -> bool:
        # hashfile used by md5sum and sha*sum tools format is: checksum filename.ext, 1 file per line.
        """
        Verify that files match their checksum.
        Note: if this is not needed, override with Manager.VERIFY_NOTHING!
        Remember to bind the function to your instance with types.MethodType(VERIFY_NOTHING, instance)
        :param files:
        :returns bool: True if everything's verified, false otherwise.
        """
        raise NotImplementedError

    @abstractmethod
    def install(self, files: list[Filename]):
        """
        Install the release to the system.
        Note: if this is not needed, override with Manager.DO_NOTHING!
        Remember to bind the function to your instance with types.MethodType(DO_NOTHING, instance)
        :param files: files to install
        """
        raise NotImplementedError

    @abstractmethod
    def cleanup(self, files: list[Filename]):
        """
        Cleanup downloaded (and/or installed) files.
        Note: if this is not needed, override with Manager.DO_NOTHING!
        Remember to bind the function to your instance with types.MethodType(DO_NOTHING, instance)
        :param files: downloaded files; interact with os.path.join(self.download_dir, filename)
        Note: it's not guaranteed the files exist!
        """
        raise NotImplementedError

    @abstractmethod
    def log(self, level: Level, msg: str):
        """
        Log internal strings. Provide concrete implementation to redirect to whatever sink is appropriate.
        Note: if this is not needed, override with Manager.LOG_NOTHING!
        Remember to bind the function to your instance with types.MethodType(LOG_NOTHING, instance)
        :param level: Log level
        :param msg: string to log
        """
        raise NotImplementedError
