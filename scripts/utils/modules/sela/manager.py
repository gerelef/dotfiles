import enum
import os
import types
from abc import ABC, abstractmethod
from typing import Callable, Self

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
    """
    The main Manager class. This class serves as the entry point to the framework; just extend and implement the
    abstract methods. After extending, instantiate and call .run(). There are a few functions that should help with
    very common functionality; see the detailed docstrings in each abstract method to guide your way. Most of the
    process is automated & encapsulated to prevent accidental tampering, however you can easily extend this with very
    custom functionality, starting with a custom ProviderFactory instance. The internals should be well documented,
    and pretty simple to understand; I'll try my best to write complete documentation any time I get. If you think
    some documentation is incomplete, or an implementation is not obvious at all, open an issue, so we can talk about
    it.
    """
    # If you're going to be overriding methods using any of the functions below, this will be an important need
    # An alternative would be to use them directly inside the method bodies, or to use the purpose-specific
    #  Manager.bind(manager, manager.foo, do_the_thing) static method.
    # https://stackoverflow.com/questions/23082509/how-is-the-self-argument-magically-passed-to-instance-methods
    # https://stackoverflow.com/questions/1015307/how-to-bind-an-unbound-method-without-calling-it
    LOG_NOTHING: Callable[[object, str], None] = lambda _, s: None
    VERIFY_NOTHING: Callable[[object, list[Filename]], bool] = lambda _, f: True
    FILTER_FIRST: Callable[[object, Release], bool] = lambda _, r: True
    DO_NOTHING: Callable[[object, list[Filename]], bool] = lambda _, f: None

    factory_cls: type[ProviderFactory] = GitHubProviderFactory

    class Level(enum.IntEnum):
        """
        Log level errors. To be used in the logging function implementation.
        Logs flagged with PROGRESS_BAR should probably be written to stdout (or stderr) directly, with sys.stdout.write.
        """
        ERROR = 32
        WARNING = 16
        DEBUG = 8
        INFO = 4
        PROGRESS_BAR = 2
        PROGRESS = 1

    def __init__(self, repository: URL, download_dir: Filename):
        """
        :param repository: direct URL to the repository to make requests
        :param download_dir: temporary download directory path
        :raises FileNotFoundError: raised if download_dir doesn't exist, or not enough permissions to execute os.stat(d)
        """
        self.repository = repository
        self.provider = Manager.factory_cls(repository).create()

        self.download_dir = download_dir
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
        Note: if you just need the latest available release, override with FILTER_FIRST (or just call it here)!
        Remember to bind the function to your instance with types.MethodType(FILTER_FIRST, instance) or Manager.bind
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
        Downloads a specific file from the url, stored in directory + filename.
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
        #
        """
        Verify that files match their checksum.
        Note: if this is not needed, override with Manager.VERIFY_NOTHING (or just call it here)!
        Remember to bind the function to your instance with types.MethodType(VERIFY_NOTHING, instance) or Manager.bind
        :param files:
        :returns bool: True if everything's verified, false otherwise.
        """
        raise NotImplementedError

    @abstractmethod
    def install(self, downloaded_files: list[Filename]):
        """
        Install the release to the system.
        Note: if this is not needed, override with Manager.DO_NOTHING (or just call it here)!
        Remember to bind the function to your instance with types.MethodType(DO_NOTHING, instance) or Manager.bind
        :param downloaded_files: downloaded files to install
        """
        raise NotImplementedError

    @abstractmethod
    def cleanup(self, files: list[Filename]):
        """
        Cleanup files.
        Note: if this is not needed, override with Manager.DO_NOTHING (or just call it here)!
        Remember to bind the function to your instance with types.MethodType(DO_NOTHING, instance) or Manager.bind
        :param files: downloaded files; interact with os.path.join(self.download_dir, filename)
        Note: it's not guaranteed the files exist!
        """
        raise NotImplementedError

    @abstractmethod
    def log(self, level: Level, msg: str):
        """
        Log internal messages. Provide concrete implementation to redirect to whatever sink is appropriate.
        Note: if this is not needed, override with Manager.LOG_NOTHING (or just call it here)!
        Remember to bind the function to your instance with types.MethodType(LOG_NOTHING, instance) or Manager.bind
        :param level: Log level
        :param msg: string to log
        """
        raise NotImplementedError

    # unfortunately, there is no BoundMethod type in python yet, womp womp
    @classmethod
    def bind(cls, manager: Self, method: types.MethodType, fn: Callable[[Self, ...], ...]):
        """
        Binds a Callable to a Manager instance, overriding the original method.
        Equivalent to writing manager.foo = types.MethodType(foo, manager)
        Note that the linter might show the type is wrong if you pass the bound method -- the linter's wrong.
        """
        setattr(manager, method.__name__, types.MethodType(fn, manager))
