from typing import Iterator

from modules.sela.api.github import get_request
from modules.sela.definitions import URL
from modules.sela.status import HTTPStatus


class GitHubDownloader:
    def __init__(self, download_url: URL):
        self.url = download_url

    def download(self, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        status, res = get_request(self.url, stream=True)
        if not status.is_successful():
            yield status, -1, -1, None

        cl = res.headers.get("Content-Length")
        total_bytes = int(cl if cl else 1)
        bread = 0
        for data in res.iter_content(chunk_size=chunk_size):
            bread += len(data)
            yield status, bread, total_bytes, data
        return
