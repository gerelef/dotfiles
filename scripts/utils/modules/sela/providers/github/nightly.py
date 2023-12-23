import re
from typing import Iterator, override

from modules.sela import exceptions
from modules.sela.definitions import URL
from modules.sela.status import HTTPStatus
from modules.sela.providers.abstract import Provider
from modules.sela.providers.github.downloader import GitHubDownloader
from modules.sela.providers.github.paging import GitHubPager
from modules.sela.releases.abstract import Release
from modules.sela.releases.branch import Branch
from modules.sela.releases.commit import Commit


class GitHubNightlyProvider(Provider):
    BRANCHES = r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/branches/?"
    COMMITS = r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/commits\?sha=[0-9a-zA-Z-_]+"

    @override
    def recurse_releases(self) -> Iterator[tuple[HTTPStatus, Commit | Branch | None]]:
        for status, release in self._iterator():
            yield status, release

        return

    @override
    def download(self, url: URL, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        return GitHubDownloader(url).download(chunk_size=chunk_size)

    @staticmethod
    @override
    def match(u: URL) -> bool:
        return bool(re.search(GitHubNightlyProvider.BRANCHES, u)) or bool(re.search(GitHubNightlyProvider.COMMITS, u))

    def _iterator(self) -> Iterator[tuple[HTTPStatus, Release | None]]:
        if re.search(GitHubNightlyProvider.BRANCHES, self.repository):
            return GitHubNightlyProvider.recurse_branches(self.repository)
        if re.search(GitHubNightlyProvider.COMMITS, self.repository):
            return GitHubNightlyProvider.recurse_commits(self.repository)

    @staticmethod
    def recurse_branches(url: URL) -> Iterator[tuple[HTTPStatus, Branch | None]]:
        """
        :param url: format expected is GitHubNightlyProvider.BRANCHES
        """
        if not re.search(GitHubNightlyProvider.BRANCHES, url):
            raise exceptions.InvalidProviderURL(url)

        url_list: list[str] = url.split("/")
        base_commits_url: str = f"{"/".join(url_list[:-1])}/commits"
        pager = GitHubPager(url).recurse()
        for status, json in pager:
            # if a request fails, it probably means either the server or our net is down, abort!
            if not status.is_successful():
                return status, None

            # get the latest url & manip url to create the download urls by calling recurse_commits
            # and getting the first element, which is the most recent one
            head = json["commit"]["sha"]
            commit_status, commit = next(GitHubNightlyProvider.recurse_commits(f"{base_commits_url}?sha={head}"))
            # if a request fails, it probably means either the server or our net is down, abort!
            if not commit_status.is_successful():
                return status, None
            # if for some reason this branch doesn't have a commit (??!!) go back and try another branch
            if commit is None:
                continue

            yield status, Branch(
                author=commit.committer,
                date=commit.date,
                message=commit.description,
                name=json["name"],
                sha=commit.name,
                src=commit.src
            )

        return

    @staticmethod
    def recurse_commits(url) -> Iterator[tuple[HTTPStatus, Commit | None]]:
        """
        :param url: format expected is GitHubNightlyProvider.COMMITS
        """
        if not re.search(GitHubNightlyProvider.COMMITS, url):
            raise exceptions.InvalidProviderURL(url)

        url_list: list[str] = url.split("/")
        base_tarball_url: str = f"{"/".join(url_list[:-1])}/tarball"
        base_zipball_url: str = f"{"/".join(url_list[:-1])}/zipball"
        pager = GitHubPager(url).recurse()
        for status, json in pager:
            # if a request fails, it probably means either the server or our net is down, abort!
            if not status.is_successful():
                return status, None

            yield status, Commit(
                author=json["commit"]["author"]["name"],
                date=json["commit"]["author"]["date"],
                message=json["commit"]["message"],
                sha=json["sha"],
                zipball=f"{base_zipball_url}/{json["sha"]}",
                tarball=f"{base_tarball_url}/{json["sha"]}"
            )
        return
