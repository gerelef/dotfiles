from abc import ABC, abstractmethod
from typing import Optional

from modules.sela.definitions import Filename, URL


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
