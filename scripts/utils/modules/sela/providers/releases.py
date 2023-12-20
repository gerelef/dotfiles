from typing import Iterator

from modules.sela.sela.definitions import HTTPStatus
from modules.sela.providers import Provider
from modules.sela.sela.releases.release import get_request, Release
from modules.sela.sela.releases.tag import Tag


class GitHubReleasesProvider(Provider):
    def recurse_releases(self) -> Iterator[tuple[HTTPStatus, Release | None]]:
        while True:
            try:
                with get_request(self.repository) as req:
                    status = HTTPStatus.create(req.status_code)
                    if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                        yield status, None
                        continue
                    json = req.json()
                    header_links = req.links

                for version in json:
                    try:
                        downloadables = {}
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
                    except IndexError:
                        pass

                url = header_links['next']['url']
            except KeyError:
                # if either next links don't exist, we're done
                break

        return None

    def download(self, chunk_size=1024 * 1024) -> Iterator[tuple[HTTPStatus, int, int, bytes | None]]:
        with get_request(self.repository, stream=True) as req:
            if HTTPStatus.create(req.status_code) != HTTPStatus.SUCCESS:
                yield HTTPStatus.create(req.status_code), -1, -1, None
            cl = req.headers.get('Content-Length')
            total_bytes = int(cl if cl else 1)
            bread = 0
            for data in req.iter_content(chunk_size=chunk_size):
                bread += len(data)
                yield HTTPStatus.create(req.status_code), bread, total_bytes, data
        return
