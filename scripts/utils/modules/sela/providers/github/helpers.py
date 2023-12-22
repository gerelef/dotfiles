from typing import Iterator

from modules.sela.definitions import HTTPStatus, URL
from modules.sela.releases.release import get_request


class GitHubPager:
    def __init__(self, url: URL):
        self.url = url

    def recurse(self) -> Iterator[tuple[HTTPStatus, dict]]:
        """
        :returns: Iterator over json data, with GitHub paging and rate limiting respected.
        """
        status, json, next_page_url = GitHubPager.get_page(self.url)
        while True:
            if status != HTTPStatus.SUCCESS:
                return status, None
            if json is None:
                return status, None

            for data in json:
                yield status, data

            # if there's no next page, return peacefully
            if not next_page_url:
                return status, None
            status, json, next_page_url = GitHubPager.get_page(next_page_url)

    @staticmethod
    def get_page(url: URL) -> tuple[HTTPStatus, dict | None, str | None]:
        """
        :returns: The HTTPStatus, the json response from the GitHub url, and the next page url, if it exists
        """
        # FIXME implement rate limiting before anything else, SUPER IMPORTANT!!!!!!!!
        raise NotImplementedError

        # FIXME implement user authentication header
        with get_request(url) as req:
            status = HTTPStatus.create(req.status_code)
            if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                return status, None, None
            json = req.json()
            next_page_url = req.links["next"]["url"] if "next" in req.links and "url" in req.links["next"] else None

        return status, json, next_page_url


class GitHubDownloader:
    def __init__(self, download_url: URL):
        self.url = download_url

    def download(self, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        with get_request(self.url, stream=True) as req:
            if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                yield HTTPStatus.create(req.status_code), -1, -1, None
            cl = req.headers.get('Content-Length')
            total_bytes = int(cl if cl else 1)
            bread = 0
            for data in req.iter_content(chunk_size=chunk_size):
                bread += len(data)
                yield HTTPStatus.create(req.status_code), bread, total_bytes, data
        return
