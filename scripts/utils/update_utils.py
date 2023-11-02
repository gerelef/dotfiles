#!/usr/bin/env python3
import os
import enum
import requests
from argparse import ArgumentParser
from datetime import datetime
from re import search as regex_search
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Generator, Sequence, Callable, Optional, TypeAlias, Self, Generic, TypeVar, Any


# Writing boilerplate code to avoid writing boilerplate code!
# https://stackoverflow.com/questions/32910096/is-there-a-way-to-auto-generate-a-str-implementation-in-python
def auto_str(cls):
    """Automatically implements __str__ for any class."""

    def __str__(self):
        return '%s(%s)' % (
            type(self).__name__,
            ', '.join('%s=%s' % item for item in vars(self).items())
        )

    cls.__str__ = __str__
    return cls


# https://stackoverflow.com/questions/390250/elegant-ways-to-support-equivalence-equality-in-python-classes
# https://stackoverflow.com/questions/2909106/whats-a-correct-and-good-way-to-implement-hash
# https://stackoverflow.com/questions/739654/how-to-make-function-decorators-and-chain-them-together
# https://www.delftstack.com/howto/python/python-multiple-decorators/
# https://stackoverflow.com/questions/20736709/how-to-iterate-over-two-dictionaries-at-once-and-get-a-result-using-values-and-k
# https://peps.python.org/pep-0485/#proposed-implementation
# https://stackoverflow.com/questions/5595425/what-is-the-best-way-to-compare-floats-for-almost-equality-in-python
def auto_eq(cls):
    """Automatically implements equality for any class. Class agnostic, and respects inheritance."""

    def __eq__(self, other):
        # if this is false, delegate this to the rhs
        if isinstance(other, self.__class__):
            s_keys = self.__dict__.keys()
            o_keys = other.__dict__.keys()
            if len(o_keys) != len(s_keys):
                return False
            for sk, ok in zip(s_keys, o_keys):
                sv = self.__dict__[sk]
                ov = other.__dict__[ok]
                if type(sv) is float and type(ov) is float:
                    if not self.__is_close__(sv, ov):
                        return False
                    continue
                if sv != ov:
                    return False
            return True

        return NotImplemented

    # noinspection PyUnusedLocal
    def __is_close__(self, a, b, rel_tol=1e-06, abs_tol=0.0):
        return abs(a - b) <= max(rel_tol * max(abs(a), abs(b)), abs_tol)

    cls.__eq__ = __eq__
    cls.__is_close__ = __is_close__

    return cls


def auto_hash(cls):
    def __hash__(self):
        return hash(tuple(sorted(self.__dict__.items())))

    cls.__hash__ = __hash__

    return cls


class Exceptions:
    class UnknownProviderException(Exception):
        pass

    class FileVerificationFailed(Exception):
        pass

    class NoReleaseFound(Exception):
        pass


Filename: TypeAlias = str
URL: TypeAlias = str


@auto_str
@auto_eq
@dataclass
class Release:
    id: int
    author_login: str

    tag_name: str
    name: str

    body: Optional[str]
    created_at: str
    published_at: str

    assets: Optional[dict[Filename, URL]]
    src: Optional[list[URL]]

    is_draft: Optional[bool] = None
    is_prerelease: Optional[bool] = None


class HTTPStatus(enum.Enum):
    """
    Group HTTP Status classes.
    """
    INFORMATIONAL = 99  # starts at > 100
    SUCCESS = 199  # starts at > 200
    REDIRECTION = 299  # starts at > 300
    CLIENT_ERROR = 399  # starts at > 400
    SERVER_ERROR = 499  # starts at > 500

    @classmethod
    def create(cls, code: int) -> Self:
        """
        :param code: HTTP Status Code.
        :returns: Group Status Class. For more information:
        https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        """
        if code > HTTPStatus.SERVER_ERROR.value:
            return HTTPStatus.SERVER_ERROR
        if code > HTTPStatus.CLIENT_ERROR.value:
            return HTTPStatus.CLIENT_ERROR
        if code > HTTPStatus.REDIRECTION.value:
            return HTTPStatus.REDIRECTION
        if code > HTTPStatus.SUCCESS.value:
            return HTTPStatus.SUCCESS
        if code > HTTPStatus.INFORMATIONAL.value:
            return HTTPStatus.INFORMATIONAL


class SupportedAPI(enum.Enum):
    """
    Supported Git providers.
    """
    GITHUB_API = "api.github.com/"
    # GITLAB_API = "gitlab.com/api/" NOT SUPPORTED YET
    GITHUB_API_REGEXR = r"(api\.github\.com\/)+"

    # GITLAB_API_REGEXR = r"(gitlab[\.a-zA-Z]*\.com\/api\/)+" NOT SUPPORTED YET

    @classmethod
    def match(cls, url: URL) -> Self | None:
        """
        Match a URL to a provider.
        :returns: the supported Provider, or None if there are no matches.
        """
        if regex_search(SupportedAPI.GITHUB_API_REGEXR.value, url):
            return SupportedAPI.GITHUB_API

        return None


Filter: TypeAlias = Callable[[Release], bool]


class Provider:
    """
    Wrapper/Facade for Git API endpoints.
    Use by instanciating with ProviderFactory and using get_releease(f: Filter)
    """

    def __init__(self, url: URL):
        """
        :param url: git project endpoint to use
        :raises Exceptions.UnknownProviderException:
        raised if the repository provider is not supported
        """
        self.repository = url

    @abstractmethod
    def __recurse_releases(self, url: URL) -> Generator[tuple[HTTPStatus, Release | None], None, None]:
        """
        Generator to get all GitHub releases for a given project.
        :param url: project endpoint
        :returns: Generator[HTTPStatus, Release]
        :raises requests.exceptions.JSONDecodeError: Raised if unable to decode Json due to mangled data
        """
        pass

    @abstractmethod
    def download(self, url: URL, chunk_size=1024 * 1024) -> Generator[
        tuple[HTTPStatus, int, int, bytes | None], None, None]:
        """
        Downloads a packet of size chunk_size from URL, which belongs to the provider defined previously.
        Generator that returns a binary data packet of size chunk_size, iteratively requested from url.
        :returns: Generator[(HTTPStatus, CurrentBytesRead, TotalBytesToRead, Data), None, None]
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        pass

    def get_release(self, f: Filter) -> Release | None:
        """
        :param f: filter to use in order to match the correct release
        :returns Release | None:
        :raises requests.exceptions.JSONDecodeError:
        """
        status: HTTPStatus
        release: Release
        for status, release in self.__recurse_releases(self.repository):
            if status.value == HTTPStatus.CLIENT_ERROR or status.value == HTTPStatus.SERVER_ERROR:
                return None
            if release is None:
                continue
            if f(release):
                return release


class ProviderFactory:
    def __init__(self):
        raise RuntimeError("Cannot instantiate static factory!")

    @classmethod
    def create(cls, url) -> Provider:
        match (SupportedAPI.match(url)):
            case SupportedAPI.GITHUB_API:
                return GitHubProvider(url=url)
            case _:
                raise Exceptions.UnknownProviderException(
                    f"Couldn't match repository URL to any supported provider!"
                )


class GitHubProvider(Provider):
    def __recurse_releases(self, url: URL) -> Generator[tuple[HTTPStatus, Release | None], None, None]:
        while True:
            try:
                with requests.get(url, allow_redirects=True, verify=True) as req:
                    status = HTTPStatus.create(req.status_code)
                    if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                        yield status, None
                        continue
                    json = req.json()
                    header_links = req.links

                for version in json:
                    try:
                        downloadables = {}
                        for asset in version["assets"]:
                            downloadables[asset["name"]] = asset["browser_download_url"]

                        yield status, Release(
                            id=int(version["id"]),
                            author_login=version["author"]["login"],
                            tag_name=version["tag_name"],
                            name=version["name"],
                            body=version["body"],
                            is_draft=bool(version["draft"]),
                            is_prerelease=bool(version["prerelease"]),
                            # https://stackoverflow.com/a/36236080/10007109
                            created_at=datetime.strptime(version["created_at"], "%Y-%m-%dT%H:%M:%SZ"),
                            published_at=datetime.strptime(version["published_at"], "%Y-%m-%dT%H:%M:%SZ"),
                            assets=downloadables,
                            src=[version["tarball_url"], version["zipball_url"]]
                        )
                    except IndexError:
                        pass

                url = header_links['next']['url']
            except KeyError:
                # if either next links don't exist, we're done
                break

        return None

    def download(self, url: URL, chunk_size=1024 * 1024) -> Generator[
        tuple[HTTPStatus, int, int, bytes | None], None, None]:
        with requests.get(url, verify=True, stream=True, allow_redirects=True) as req:
            if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                yield HTTPStatus.create(req.status_code), -1, -1, None
            total_bytes_read = int(req.headers.get('content-length'))
            bread = 0
            for data in req.iter_content(chunk_size=chunk_size):
                bread += len(data)
                yield HTTPStatus.create(req.status_code), bread, total_bytes_read, data
        return


class Checksum(enum.Enum):
    MD5SUM = "md5"
    SHA1SUM = "sha1"
    SHA256SUM = "sha256"
    SHA384SUM = "sha384"
    SHA512SUM = "sha512"

    @classmethod
    def match(cls, filename: Filename) -> Self:
        # last part *should* always be the file type
        fn_sanitized = filename.lower().split(".")[-1]
        if Checksum.MD5SUM.value in fn_sanitized:
            return Checksum.MD5SUM
        if Checksum.SHA1SUM.value in fn_sanitized:
            return Checksum.SHA1SUM
        if Checksum.SHA256SUM.value in fn_sanitized:
            return Checksum.SHA256SUM
        if Checksum.SHA384SUM.value in fn_sanitized:
            return Checksum.SHA384SUM
        if Checksum.SHA512SUM.value in fn_sanitized:
            return Checksum.SHA512SUM


@auto_str
class Manager(ABC):
    LOG_NOTHING: Callable[[str], None] = lambda s: None
    VERIFY_NOTHING: Callable[[list[Filename]], bool] = lambda f: True
    FILTER_FIRST: Callable[[Release], bool] = lambda r: True
    DO_NOTHING: Callable[[list[Filename]], bool] = lambda f: None

    class Level(enum.IntEnum):
        ERROR = 16
        WARNING = 8
        DEBUG = 4
        INFO = 2
        PROGRESS = 1

    def __init__(self, repository: URL, download_dir: Filename = "/tmp/"):
        """
        :param repository: direct URL to the repository to make requests
        :param download_dir: download directory path
        :raises Provider.Exceptions.UnknownProviderException: raised if the repository provider is not supported
        :raises FileNotFoundError: raised if download_dir doesn't exist, or not enough permissions to execute os.stat(d)
        """
        self.repository = repository
        self.provider = ProviderFactory.create(self.repository)

        self.download_dir = download_dir
        if not os.path.exists(self.download_dir):
            raise FileNotFoundError(
                f"Couldn't find, or not enough permissions to use os.stat(), on {self.download_dir}")

    def run(self) -> None:
        """
        :raises Exceptions.NoReleaseFound: raised when no release matched
        :raises RuntimeError: raised when download requests errored
        :raises Exceptions.FileVerificationFailed: raised when file verification failed
        """
        files: list[Filename] = []
        self.log(Manager.Level.PROGRESS, "Starting preprocessing...")
        try:
            r = self.provider.get_release(self.filter)
            if not r:
                self.log(Manager.Level.ERROR, "No release found, or matched! Is everything set OK?")
                raise Exceptions.NoReleaseFound()
            downloadables = self.get_downloads(r)
            self.log(Manager.Level.PROGRESS, "Starting downloads...")
            for fn, url in downloadables.items():
                files.append(fn)
                status = self.download(os.path.join(self.download_dir, fn), url)
                if status.value == HTTPStatus.CLIENT_ERROR or status.value == HTTPStatus.SERVER_ERROR:
                    self.log(Manager.Level.ERROR, f"Got HTTPStatus {status.value}!")
                    raise RuntimeError(f"Got HTTPStatus {status.value}!")
            self.log(Manager.Level.PROGRESS, "Starting verification...")
            if not self.verify(files):
                self.log(Manager.Level.ERROR, "Couldn't verify files!")
                raise Exceptions.FileVerificationFailed()
            self.log(Manager.Level.PROGRESS, "Starting install...")
            self.install(files)
        except KeyboardInterrupt:
            self.log(Manager.Level.WARNING, "Aborted by user.")
            exit(130)
        finally:
            self.cleanup(files)
            self.log(Manager.Level.PROGRESS, "Done.")

    @abstractmethod
    def filter(self, release: Release) -> bool:
        """
        Check if this is the release we want to download.
        Note: if you just need the latest available release, override with FILTER_FIRST.
        :param release:
        :returns bool: True if attributes match what we want to download, false otherwise.
        """
        pass

    @abstractmethod
    def get_downloads(self, r: Release) -> dict[Filename, URL]:
        """
        Get the assets that we'll download from a specific Release.
        :returns dict[Filename, URL]: a dict where filenames match the URL we'll download from
        """
        pass

    def download(self, filename: Filename, url: URL) -> HTTPStatus:
        """
        Downloads a specific file fromn url, stored in self.directory + filename.
        Finishes early upon HTTPStatus error.
        :param filename: filename to store as
        :param url: url to download from
        :return: last HTTPStatus received by self.provider.download
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        self.log(Manager.Level.PROGRESS, f"Downloading {os.path.join(self.download_dir, filename)}")
        with open(os.path.join(self.download_dir, filename), "wb") as out:
            for status, bread, btotal, data in self.provider.download(url):
                if status.value == HTTPStatus.CLIENT_ERROR or status.value == HTTPStatus.SERVER_ERROR:
                    break
                self.log(Manager.Level.PROGRESS, f"\r{progress_bar(bread, btotal)}")
                out.write(data)
            # noinspection PyUnboundLocalVariable
            return status

    @abstractmethod
    def verify(self, files: list[Filename]) -> bool:
        # hashfile used by md5sum and sha*sum tools format is: checksum filename.ext, 1 file per line.
        """
        Verify that files match their checksum.
        Note: if this is not needed, override with Manager.VERIFY_NOTHING
        :param files:
        :returns bool: True if everything's verified, false otherwise.
        """
        pass

    @abstractmethod
    def install(self, files: list[Filename]):
        """
        Install the release to the system.
        Note: if this is not needed, override with Manager.DO_NOTHING
        :param files: files to install
        """
        pass

    @abstractmethod
    def cleanup(self, files: list[Filename]):
        """
        Cleanup downloaded (and/or installed) files.
        Note: if this is not needed, override with Manager.DO_NOTHING
        :param files: downloaded files; interact with os.path.join(self.download_dir, filename)
        Note: it's not guaranteed the files exist!
        """
        pass

    @abstractmethod
    def log(self, level: Level, msg: str):
        """
        Log internal strings. Provide concrete implementation to redirect to whatever sink is appropriate.
        Note: if this is not needed, override with Manager.LOG_NOTHING
        :param level: Log level
        :param msg: string to log
        """
        pass


DEFAULT_ARGUMENTS = {
    "--list-versions": {
        "help": "List available version(s) to download from remote.",
        "required": False,
        "default": False,
        "action": "store_true"
    },
    "--version": {
        "help": "Specify a version to install. Default is latest.",
        "required": False,
        "default": None
    },
    "--keep": {
        "help": "Specify if downloaded files will be kept after finishing.",
        "required": False,
        "default": False,
        "action": "store_true"
    },
    "--temporary": {
        "help": "Specify temporary directory files will be downloaded at. Default is /tmp/",
        "required": False,
        "default": "/tmp/",
        "type": str
    },
    "--destination": {
        "help": "Specify installation directory.",
        "required": False,
        "default": None,
        "type": str
    },
    "--unsafe": {
        "help": "Specify if file verification will be skipped. Set by default if unsupported by the repository.",
        "required": False,
        "default": False,
        "action": "store_true"
    },
}


# TODO add compgen generator to use along with this (?)
def get_default_argparser(description):
    import argparse as ap
    p = ap.ArgumentParser(description=description)
    for argname, argopts in DEFAULT_ARGUMENTS.items():
        p.add_argument(argname, **argopts)
    return p


def run_subprocess(commands: Sequence[str] | str, cwd: Filename) -> bool:
    """
    :param cwd: current working directory
    :param commands: commands to run in subshell, sequence of or singular string(s)
    :parm cwd: working directory for subshell
    """
    import subprocess
    import os
    return subprocess.run(commands, cwd=os.path.expanduser(cwd)).returncode == 0


def euid_is_root() -> bool:
    """Returns True if script is running as root."""
    import os
    return os.geteuid() == 0


def progress_bar(current, total) -> str:
    """Return a simple percentage string."""
    return f"{current}/{total} | {round((current / total) * 100, 2)}%"
