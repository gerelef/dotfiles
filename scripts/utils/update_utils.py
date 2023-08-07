#!/usr/bin/env python3
from dataclasses import dataclass
from typing import Generator, List, Callable


# Writing boilerplate code to avoid writing boilerplate code!
# https://stackoverflow.com/questions/32910096/is-there-a-way-to-auto-generate-a-str-implementation-in-python
def auto_str(cls):
    """Automatically implements __str__ for any class."""

    def __str__(self):
        return '%s(%s)' % (
            type(self).__name__,
            ', '.join('%s=%s' % item for item in vars(self).items())
        )

    cls.__str__ = __str__
    return cls


# https://stackoverflow.com/questions/390250/elegant-ways-to-support-equivalence-equality-in-python-classes
# https://stackoverflow.com/questions/2909106/whats-a-correct-and-good-way-to-implement-hash
# https://stackoverflow.com/questions/739654/how-to-make-function-decorators-and-chain-them-together
# https://www.delftstack.com/howto/python/python-multiple-decorators/
# https://stackoverflow.com/questions/20736709/how-to-iterate-over-two-dictionaries-at-once-and-get-a-result-using-values-and-k
# https://peps.python.org/pep-0485/#proposed-implementation
# https://stackoverflow.com/questions/5595425/what-is-the-best-way-to-compare-floats-for-almost-equality-in-python
def auto_eq(cls):
    """Automatically implements equality for any class. Class agnostic, and respects inheritance."""

    def __eq__(self, other):
        # if this is false, delegate this to the rhs
        if isinstance(other, self.__class__):
            s_keys = self.__dict__.keys()
            o_keys = other.__dict__.keys()
            if len(o_keys) != len(s_keys):
                return False
            for sk, ok in zip(s_keys, o_keys):
                sv = self.__dict__[sk]
                ov = other.__dict__[ok]
                if type(sv) is float and type(ov) is float:
                    if not self.__is_close__(sv, ov):
                        return False
                    continue
                if sv != ov:
                    return False
            return True

        return NotImplemented

    # noinspection PyUnusedLocal
    def __is_close__(self, a, b, rel_tol=1e-06, abs_tol=0.0):
        return abs(a - b) <= max(rel_tol * max(abs(a), abs(b)), abs_tol)

    cls.__eq__ = __eq__
    cls.__is_close__ = __is_close__

    return cls


def auto_hash(cls):
    def __hash__(self):
        return hash(tuple(sorted(self.__dict__.items())))

    cls.__hash__ = __hash__

    return cls


@auto_str
@auto_eq
@dataclass
class __Release:
    id: int
    author_login: str

    tag_name: str
    name: str

    body: str
    is_draft: bool
    is_prerelease: bool
    created_at: str
    published_at: str

    assets: dict[str, str]  # filename, link


def run_subprocess(commands, cwd) -> bool:
    """Runs a number of Commands in  the Currently Working Directory"""
    import subprocess
    from os import path
    return subprocess.run(commands, cwd=path.expanduser(cwd)).returncode == 0


def get_github_releases(url, recurse=False) -> list[__Release] | None:
    """Gets all the GitHub releases for a given match, and return a list of Release class. Can use GitHub release
    paging to find all compatible releases."""
    from datetime import datetime
    import requests

    releases: list[__Release] = []
    while True:
        try:
            with requests.get(url, verify=True) as req:
                if req.status_code != 200:
                    print(f"Got status code {req.status_code}", file=sys.stderr)
                    exit(1)
                releases_recvd = req.json()
                releases_links = req.links

            for version in releases_recvd:
                try:
                    assets = {}
                    for asset in version["assets"]:
                        assets[asset["name"]] = asset["browser_download_url"]

                    releases.append(
                        __Release(
                            id=int(version["id"]),
                            author_login=version["author"]["login"],
                            tag_name=version["tag_name"],
                            name=version["name"],
                            body=version["body"],
                            is_draft=bool(version["draft"]),
                            is_prerelease=bool(version["prerelease"]),
                            # https://stackoverflow.com/a/36236080/10007109
                            created_at=datetime.strptime(version["created_at"], "%Y-%m-%dT%H:%M:%SZ"),
                            published_at=datetime.strptime(version["published_at"], "%Y-%m-%dT%H:%M:%SZ"),
                            assets=assets
                        )
                    )
                except IndexError:
                    pass

            if not recurse:
                break

            url = releases_links['next']['url']
        except KeyError:
            # if either next links don't exist, we're done
            break
        except requests.exceptions.JSONDecodeError:
            # if the json has errored return None to indicate error
            return None

    return releases


def download(url, chunk_size=1024 * 1024) -> Generator[int, int, bin]:
    """Generator that returns a binary data packet of size chunk_size, requested from url. First returnee is the
    currently read bytes, second is the total read bytes, and the third is the actual data itself."""
    import requests
    with requests.get(url, verify=True, stream=True, allow_redirects=True) as req:
        btotal = int(req.headers.get('content-length'))
        bread = 0
        for data in req.iter_content(chunk_size=chunk_size):
            bread += len(data)
            yield bread, btotal, data
    return


def match_correct_release(link: str, title: str=None, _filter: Callable[str, ...]=None):
    """
    Match correct release by checking if substring title is inside release.tag_name.lower().
    Releases that return false on _filter (if provided) release.tag_name.lower() are not considered.
    """
    releases = get_github_releases(link, recurse=False if not title else True)
    if not releases:
        print(f"Unknown error, couldn't get all github releases for {link}")
        exit(1)

    print(f"Found {len(releases)} valid releases.")
    if not title:
        return releases[0]

    for release in releases:
        # if we have a filter, and the results it False, continue to the next result
        if _filter and not _filter(release.tag_name.lower()):
            continue
        if title in release.tag_name.lower():
            return release

    return None


def echo_progress_bar_simple(current, total, stream):
    """Echo a simple percentage in the stream. Stream must be a stream of type TextIOWrapper, or any other class that
    has a .write(str) and .flush() method."""
    stream.write(f"\r{round((current / total) * 100, 2)}%")
    stream.flush()


def echo_progress_bar_complex(current, total, stream, max_columns, use_ascii=False):
    """Echo a complex progress bar in the stream. Stream must be a stream of type TextIOWrapper, or any other class
    that has a .write(str) and .flush() method."""
    empty_space = " " if use_ascii else "\033[1m\033[38;5;196m―\033[0m"  # bold, light_red & clean_colour
    filled_space = "-" if use_ascii else "\033[1m\033[38;5;34m―\033[0m"  # bold, green & clean_colour
    # total bar length: we're going to use the max columns with a padding of 6 characters
    #  for the "[" "]" "999%" pads.
    percentage_str = f"{round((current / total) * 100, 1)}%"
    bar_length = max_columns - len(percentage_str) - 2 # 2 for safety, sometimes tput cols overshoots this. 
    bar = ["\r", "["] + [empty_space] * bar_length + ["]"] + list(f"\033[1m\033[38;5;34m{percentage_str}\033[0m")
    for i in range(2, bar_length + 2):
        if round(i / (bar_length + 1), 2) <= round(current / total, 2):
            bar[i] = filled_space
    stream.write("".join(bar))
    stream.flush()


def is_root() -> bool:
    """Returns True if script is running as root."""
    import os
    return os.geteuid() == 0


def get_all_subdirectories(path) -> list[str]:
    """Returns the filenames of all subdirectories in a path."""
    import os
    return os.listdir(path=path)


if __name__ == "__main__":
    from time import sleep
    import sys

    print(f"Script is running as {'root' if is_root() else 'user'}")

    for i in range(100):
        echo_progress_bar_simple(i, 99, sys.stdout)
        sleep(0.1)

    print()

    for i in range(100):
        echo_progress_bar_complex(i, 99, sys.stdout, 50)
        sleep(0.1)

    print()

    for i in range(100):
        echo_progress_bar_complex(i, 99, sys.stdout, 16)
        sleep(0.1)

    print()

    for release in get_github_releases("https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"):
        print(release.name)
        sleep(0.1)

    for release in get_github_releases(
            "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases",
            recurse=True):
        print(release)
        sleep(0.1)

    if run_subprocess(["echo", "hello", "bash!" "$PWD"], "~"):
        print("Success!")
