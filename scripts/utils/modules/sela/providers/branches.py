from typing import Iterator

from modules.sela.sela.definitions import HTTPStatus
from modules.sela.providers import Provider
from modules.sela.sela.releases.release import Release


class GitHubBranchesProvider(Provider):
    def recurse_releases(self) -> Iterator[tuple[HTTPStatus, Release | None]]:
        # TODO implement
        raise NotImplementedError

    def download(self, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        # TODO implement
        raise NotImplementedError
