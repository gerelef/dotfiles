import re
from typing import Iterator, override, final

from modules.sela.definitions import URL
from modules.sela.status import HTTPStatus
from modules.sela.providers.abstract import Provider
from modules.sela.providers.github.downloader import GitHubDownloader
from modules.sela.providers.github.paging import GitHubPager
from modules.sela.releases.abstract import Release
from modules.sela.releases.tag import Tag


@final
class GitHubReleasesProvider(Provider):
    def __init__(self, url: URL):
        super().__init__(url)

    @override
    def recurse_releases(self) -> Iterator[tuple[HTTPStatus, Release | None]]:
        pager = GitHubPager(self.repository).recurse()
        for status, version in pager:
            # if a request fails, it probably means either the server or our net is down, abort!
            if not status.is_successful():
                return status, None

            downloadables = {}
            if "assets" in version:
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

        return None

    @override
    def download(self, url: URL, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        return GitHubDownloader(url).download(chunk_size=chunk_size)

    @staticmethod
    @override
    def match(u: URL) -> bool:
        return bool(re.search(r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/releases/?", u))
