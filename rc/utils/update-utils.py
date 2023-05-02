#!/usr/bin/env python3

# TODO
def run_subprocess(commands, cwd) -> bool:
    """Runs a number of Commands in  the Currently Working Directory"""
    return sp.run(commands, cwd=cwd).returncode) == 0

# TODO
def get_github_releases(url, recurse=False) -> bool:
    """Gets all the github releases for a given match, and return the appropriate class. Can use github release paging to find all compatible releases."""
    return True


def download(url, chunk_size=1024*1024) -> tuple(int, int, bin):
    """Generator that returns a binary data packet of size chunk_size, requested from url. First returnee is the currently read bytes, second is the total read bytes, and the third is the actual data itself. """
    import requests
    with requests.get(url, verify=True, stream=True, allow_redirects=True) as req:
        btotal = int(req.headers.get('content-length'))
        bread = 0
        for data in req.iter_content(chunk_size=chunk_size):
            bread += len(data)
            yield bread, btotal, data
    return 


def echo_progress_bar_simple(current, total, stream):
    """Echo a simple percentage in the stream. Stream must be a stream of type TextIOWrapper, or any other class that has a .write(str) and .flush() method."""
    stream.write(f"\r{round((bread/btotal)*100, 2)}%")
    stream.flush()


# TODO
def echo_progress_bar_complex(current, total, stream, max_columns, use_ascii=False):
    """Echo a complex progress bar in the stream. Stream must be a stream of type TextIOWrapper, or any other class that has a .write(str) and .flush() method."""
    pass


def is_root() -> bool:
    """Returns True if script is running as root."""
    import os
    return os.geteuid() == 0


def get_all_subdirectories(path) -> list[str]:
    """Returns the filenames of all subdirectories in a path."""
    import os
    return os.listdir(path=path)


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

