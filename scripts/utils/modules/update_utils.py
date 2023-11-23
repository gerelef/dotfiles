#!/usr/bin/env python3
import argparse as ap
import enum
import os
import re
import subprocess
import sys
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Sequence, Callable, Optional, Self, Iterator

try:
    import requests
except NameError:
    print(
        "Couldn't find requests library! Is it installed in the current environment?",
        file=sys.stderr
    )
    exit(1)


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

    class NoAssetsFound(Exception):
        pass

    class DependencyMissing(Exception):
        pass


type Filename = str
type URL = str


def get_request(url: URL, *args, **kwargs):
    version_header = {"X-GitHub-Api-Version": "2022-11-28"}
    return requests.get(url, verify=True, allow_redirects=True, headers=version_header, *args, **kwargs)


class Release(ABC):
    """
    Common interface for Releass.
    They may either be actual Releases, or specific commits from *any* branch.
    """

    @property
    @abstractmethod
    def assets(self) -> Optional[dict[Filename, URL]]:
        raise NotImplementedError

    @property
    @abstractmethod
    def src(self) -> Optional[list[URL]]:
        raise NotImplementedError

    @property
    @abstractmethod
    def name(self) -> str:
        raise NotImplementedError

    @property
    @abstractmethod
    def name_human_readable(self) -> str:
        raise NotImplementedError

    @property
    @abstractmethod
    def description(self) -> Optional[str]:
        raise NotImplementedError

    @property
    @abstractmethod
    def committer(self) -> str:
        raise NotImplementedError

    @property
    @abstractmethod
    def date(self) -> str:
        raise NotImplementedError


class Commit(Release):

    def __init__(self):
        raise NotImplementedError

    @property
    def assets(self) -> Optional[dict[Filename, URL]]:
        raise NotImplementedError

    @property
    def src(self) -> Optional[list[URL]]:
        raise NotImplementedError

    @property
    def name(self) -> str:
        raise NotImplementedError

    @property
    def name_human_readable(self) -> str:
        raise NotImplementedError

    @property
    def description(self) -> Optional[str]:
        raise NotImplementedError

    @property
    def committer(self) -> str:
        raise NotImplementedError

    @property
    def date(self) -> str:
        raise NotImplementedError


class Tag(Release):

    def __init__(self,
                 author: str,
                 tag: str,
                 name: str,
                 body: str,
                 date: str,
                 assets: dict[str, str],
                 src: list[str]):
        self.__author = author
        self.__tag = tag
        self.__name = name
        self.__body = body
        self.__date = date
        self.__assets = assets
        self.__src = src

    @property
    def name(self) -> str:
        return self.__tag

    @property
    def name_human_readable(self) -> str:
        return self.__name

    @property
    def description(self) -> Optional[str]:
        return self.__body

    @property
    def committer(self) -> str:
        return self.__author

    @property
    def date(self) -> str:
        return self.__date

    @property
    def assets(self) -> Optional[dict[Filename, URL]]:
        return self.__assets

    @property
    def src(self) -> Optional[list[URL]]:
        return self.__src


class HTTPStatus(enum.IntEnum):
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
        if code > HTTPStatus.SERVER_ERROR:
            return HTTPStatus.SERVER_ERROR
        if code > HTTPStatus.CLIENT_ERROR:
            return HTTPStatus.CLIENT_ERROR
        if code > HTTPStatus.REDIRECTION:
            return HTTPStatus.REDIRECTION
        if code > HTTPStatus.SUCCESS:
            return HTTPStatus.SUCCESS
        if code > HTTPStatus.INFORMATIONAL:
            return HTTPStatus.INFORMATIONAL


type Filter = Callable[[Release], bool]


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
    def recurse_releases(self, url: URL) -> Iterator[tuple[HTTPStatus, Release | None]]:
        """
        Generator to get all GitHub releases for a given project.
        :param url: project endpoint
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
        for status, release in self.recurse_releases(self.repository):
            if status == HTTPStatus.CLIENT_ERROR or status == HTTPStatus.SERVER_ERROR:
                return None
            if release is None:
                continue
            if f(release):
                return release


class GitHubReleasesProvider(Provider):
    def recurse_releases(self, url: URL) -> Iterator[tuple[HTTPStatus, Release | None]]:
        while True:
            try:
                with get_request(url) as req:
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

                        yield status, Tag(
                            author=version["author"]["login"],
                            tag=version["tag_name"],
                            name=version["name"],
                            body=version["body"],
                            # https://stackoverflow.com/a/36236080/10007109
                            date=version["published_at"],
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

    def download(self, url: URL, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        with get_request(url, stream=True) as req:
            if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                yield HTTPStatus.create(req.status_code), -1, -1, None
            cl = req.headers.get('Content-Length')
            total_bytes = int(cl if cl else 1)
            bread = 0
            for data in req.iter_content(chunk_size=chunk_size):
                bread += len(data)
                yield HTTPStatus.create(req.status_code), bread, total_bytes, data
        return


class GitHubBranchesProvider(Provider):
    def recurse_releases(self, url: URL) -> Iterator[tuple[HTTPStatus, Release | None]]:
        raise NotImplementedError

    def download(self, url: URL, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        raise NotImplementedError


class ProviderFactory:
    """
    Supported Git provider factory.
    """
    GITHUB_RELEASES_API_REGEX = re.compile(r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/releases/?")
    GITHUB_BRANCHES_API_REGEX = re.compile(r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/branches/?")

    # GITLAB_API_REGEXR = r"(gitlab[\.a-zA-Z]*\.com\/api\/)+" NOT SUPPORTED YET

    def __init__(self):
        raise RuntimeError("Cannot instantiate static factory!")

    @classmethod
    def match(cls, url: URL) -> Self | None:
        """
        Match a URL to a provider.
        :returns: the supported Provider, or None if there are no matches.
        """
        if ProviderFactory.GITHUB_RELEASES_API_REGEX.search(url):
            return ProviderFactory.GITHUB_RELEASES_API_REGEX
        if ProviderFactory.GITHUB_BRANCHES_API_REGEX.search(url):
            raise ProviderFactory.GITHUB_BRANCHES_API_REGEX

        return None

    @staticmethod
    def create(url: URL) -> Provider:
        match (ProviderFactory.match(url)):
            case ProviderFactory.GITHUB_RELEASES_API_REGEX:
                return GitHubReleasesProvider(url=url)
            case ProviderFactory.GITHUB_BRANCHES_API_REGEX:
                return GitHubBranchesProvider(url=url)
            case _:
                raise Exceptions.UnknownProviderException(
                    f"Couldn't match repository URL to any supported provider!"
                )


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

    def __init__(self, repository: URL, temp_dir: Filename):
        """
        :param repository: direct URL to the repository to make requests
        :param temp_dir: temporary download directory path
        :raises Provider.Exceptions.UnknownProviderException: raised if the repository provider is not supported
        :raises FileNotFoundError: raised if download_dir doesn't exist, or not enough permissions to execute os.stat(d)
        """
        self.repository = repository
        self.provider = ProviderFactory.create(repository)

        self.download_dir = temp_dir
        if not os.path.exists(self.download_dir):
            raise FileNotFoundError(
                f"Couldn't find, or not enough permissions to use os.stat(), on {self.download_dir}")

    def run(self) -> None:
        """
        :raises RuntimeError: raised when download requests errored or ended abruptly with HTTP Status != 200
        :raises Exceptions.NoReleaseFound: raised when no release matched
        :raises Exceptions.NoAssetsFound: raised when no assets are available/returned
        :raises Exceptions.FileVerificationFailed: raised when file verification failed
        :raises requests.JSONDecodeError: raised when there's malformed JSON in the response
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        files: list[Filename] = []
        self.log(Manager.Level.PROGRESS, "Starting preprocessing...")
        try:
            r = self.provider.get_release(self.filter)
            if not r:
                raise Exceptions.NoReleaseFound("No release found, or matched! Is everything OK?")

            downloadables = self.get_assets(r)
            if not downloadables:
                raise Exceptions.NoAssetsFound("No assets found, or matched! Is everything OK?")

            self.log(Manager.Level.PROGRESS, "Starting downloads...")
            for fn, url in downloadables.items():
                files.append(fn)
                self.log(Manager.Level.PROGRESS, f"Downloading {fn}")
                status = self.download(os.path.join(self.download_dir, fn), url)
                if status == HTTPStatus.CLIENT_ERROR or status == HTTPStatus.SERVER_ERROR:
                    raise RuntimeError(f"Got HTTPStatus {status}!")

            self.log(Manager.Level.PROGRESS, "Verifying...")
            if not self.verify(files):
                raise Exceptions.FileVerificationFailed("Couldn't verify files!")

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
                if status == HTTPStatus.CLIENT_ERROR or status == HTTPStatus.SERVER_ERROR:
                    return status
                self.log(Manager.Level.PROGRESS_BAR,
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


# TODO add ArgHandler so there's less ArgumentParser boilerplate in scripts..
# TODO add compgen generator from ArgumentParser
class ArgumentParserBuilder:
    # FIXME add documentation
    DEFAULT_VERSION: tuple[(str, ...), dict[...]] = (
        ("-v", "--version"),
        {
            "help": "Specify a version to install.",
            "required": False,
            "default": None
        }
    )

    DEFAULT_KEEP: tuple[(str, ...), dict[...]] = (
        ("-k", "--keep"),
        {
            "help": "Specify if temporary file cleanup will be performed.",
            "required": False,
            "default": False,
            "action": "store_true"
        }
    )

    DEFAULT_TEMPORARY: tuple[(str, ...), dict[...]] = (
        ("-t", "--temporary"),
        {
            "help": "Specify temporary (download) directory files.",
            "required": False,
            "default": None,
            "type": str
        }
    )

    DEFAULT_DESTINATION: tuple[(str, ...), dict[...]] = (
        ("-d", "--destination"),
        {
            "help": "Specify installation directory.",
            "required": False,
            "default": None,
            "type": str
        }
    )

    DEFAULT_UNSAFE: tuple[(str, ...), dict[...]] = (
        ("-u", "--unsafe"),
        {
            "help": "Specify if file verification will be skipped.",
            "required": False,
            "default": False,
            "action": "store_true"
        }
    )

    def __init__(self, description: str):
        self.parser = ap.ArgumentParser(description=description)

    def add_version(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_VERSION
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_keep(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_KEEP
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_temporary(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_TEMPORARY
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_destination(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_DESTINATION
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_unsafe(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_UNSAFE
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_arguments(self, flags_kwargs_dict: dict[(str, ...), dict[...]]) -> Self:
        for flags, argopts in flags_kwargs_dict.items():
            self.parser.add_argument(*flags, **argopts)
        return self

    def add_mutually_exclusive_group(self, flags_kwargs_dict: dict[(str, ...), dict[...]], required=True) -> Self:
        meg = self.parser.add_mutually_exclusive_group(required=required)
        for flags, argopts in flags_kwargs_dict.items():
            meg.add_argument(*flags, **argopts)
        return self

    def build(self) -> ap.ArgumentParser:
        return self.parser


def run_subprocess(commands: Sequence[str] | str, cwd: Filename = "~") -> tuple[bool, str, str]:
    """
    :param cwd: current working directory
    :param commands: commands to run in subshell, sequence of or singular string(s)
    :parm cwd: working directory for subshell
    :returns: status code (True on success, False on error), stdout, stderr 
    """
    result = subprocess.run(
        commands,
        cwd=os.path.abspath(os.path.expanduser(cwd)),
        capture_output=True,
        text=True,
    )
    return result.returncode == 0, result.stdout, result.stderr


def euid_is_root() -> bool:
    """Returns True if script is running as root."""
    return os.geteuid() == 0
