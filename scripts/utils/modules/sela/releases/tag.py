from typing import Optional, final

from modules.sela.definitions import URL, Filename
from modules.sela.helpers import auto_str
from modules.sela.releases.abstract import Release

@final
@auto_str
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
