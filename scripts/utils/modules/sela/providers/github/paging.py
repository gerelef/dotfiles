from typing import Iterator, final

from modules.sela.api.github import get_request
from modules.sela.definitions import URL
from modules.sela.status import HTTPStatus


@final
class GitHubPager:
    def __init__(self, url: URL):
        self.url = url

    def recurse(self) -> Iterator[tuple[HTTPStatus, dict]]:
        """
        :returns: Iterator over json data, with GitHub paging and rate limiting respected.
        """
        status, json, next_page_url = GitHubPager.get_page(self.url)
        while True:
            if not status.is_successful():
                return status, None

            for data in json:
                yield status, data

            # if there's no next page, return peacefully
            if not next_page_url:
                return status, json

            status, json, next_page_url = GitHubPager.get_page(next_page_url)

    @staticmethod
    def get_page(url: URL) -> tuple[HTTPStatus, dict | None, str | None]:
        """
        :returns: The HTTPStatus, the json response from the GitHub url, and the next page url, if it exists
        """
        status, res = get_request(url)
        if not status.is_successful():
            return status, None, None

        json = res.json()
        next_page_url = res.links["next"]["url"] if "next" in res.links and "url" in res.links["next"] else None

        return status, json, next_page_url
