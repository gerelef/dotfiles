import sys
from abc import ABC, abstractmethod
from typing import Optional

from modules.sela.sela.definitions import Filename, URL


class Release(ABC):
    """
    Common interface for Releases.
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


def get_request(url: URL, *args, **kwargs):
    try:
        import requests
    except NameError:
        print(
            "Couldn't find requests library! Is it installed in the current environment?",
            file=sys.stderr
        )
        exit(1)
    version_header = {"X-GitHub-Api-Version": "2022-11-28"}
    return requests.get(url, verify=True, allow_redirects=True, headers=version_header, *args, **kwargs)
