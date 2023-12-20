from typing import Optional

from modules.sela.sela.definitions import Filename, URL
from modules.sela.sela.releases.release import Release


class Commit(Release):

    def __init__(self):
        raise NotImplementedError  # TODO implement

    @property
    def assets(self) -> Optional[dict[Filename, URL]]:
        raise NotImplementedError  # TODO implement

    @property
    def src(self) -> Optional[list[URL]]:
        raise NotImplementedError  # TODO implement

    @property
    def name(self) -> str:
        raise NotImplementedError  # TODO implement

    @property
    def name_human_readable(self) -> str:
        raise NotImplementedError  # TODO implement

    @property
    def description(self) -> Optional[str]:
        raise NotImplementedError  # TODO implement

    @property
    def committer(self) -> str:
        raise NotImplementedError  # TODO implement

    @property
    def date(self) -> str:
        raise NotImplementedError  # TODO implement
