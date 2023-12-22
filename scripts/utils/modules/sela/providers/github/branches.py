import re
from typing import Iterator, override

from modules.sela.definitions import HTTPStatus, URL
from modules.sela.providers.abstract import Provider
from modules.sela.providers.github.helpers import GitHubDownloader
from modules.sela.releases.release import Release


class GitHubBranchesProvider(Provider):
    BRANCHES = r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/branches/?"
    COMMITS = r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/commits\?sha=[0-9a-zA-Z-_]+"
    TREE = r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/git/trees/[a-zA-Z0-9-_]+\?recursive=[0-1]"

    @override
    def recurse_releases(self) -> Iterator[tuple[HTTPStatus, Release | None]]:
        # TODO implement
        raise NotImplementedError

    @override
    def download(self, url: URL, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        return GitHubDownloader(url).download(chunk_size=chunk_size)

    @staticmethod
    @override
    def match(u: URL) -> bool:
        return (bool(re.search(GitHubBranchesProvider.BRANCHES, u)) or
                bool(re.search(GitHubBranchesProvider.COMMITS, u)) or
                bool(re.search(GitHubBranchesProvider.TREE, u)))
