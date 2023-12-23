from typing import Optional, final

from modules.sela.definitions import Filename, URL
from modules.sela.helpers import auto_str
from modules.sela.releases.abstract import Release


@final
@auto_str
class Commit(Release):
    def __init__(self,
                 author: str,
                 date: str,
                 message: str,
                 sha: str,
                 tarball: str,
                 zipball: str):
        """
        :param author: author of the latest commit in the current branch
        :param date: date of the latest commit
        :param message: message of the latest commit
        :param sha: sha of the latest commit
        :param tarball: URL to download the tarball from, should point to the latest commit in the current branch
        :param zipball: URL to download the zipball from, should point to the latest commit in the current branch
        """
        self.__author = author
        self.__date = date
        self.__message = message
        self.__sha = sha
        self.__tarball = tarball
        self.__zipball = zipball

    @property
    def assets(self) -> Optional[dict[Filename, URL]]:
        return None

    @property
    def src(self) -> Optional[list[URL]]:
        return [self.__zipball, self.__tarball]

    @property
    def name(self) -> str:
        return self.__sha

    @property
    def name_human_readable(self) -> str:
        return self.__sha[:8]

    @property
    def description(self) -> Optional[str]:
        return self.__message

    @property
    def committer(self) -> str:
        return self.__author

    @property
    def date(self) -> str:
        return self.__date
