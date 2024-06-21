#!/usr/bin/env python3.12
# Writing boilerplate code to avoid writing boilerplate code!
# https://stackoverflow.com/questions/32910096/is-there-a-way-to-auto-generate-a-str-implementation-in-python
import logging
import os
import subprocess
import random
import string
from random import randint
from pathlib import Path
from typing import Sequence


LOREM_IPSUM_TOKENS = [
    'pulvinar', 'a', 'eleifend', 'libero', 'elit', 'neque', 'ullamcorper', 'commodo', 'sodales', 'magna',
    'incididunt', 'at', 'risus', 'lectus', 'enim', 'ornare', 'eu', 'lorem', 'nec', 'tellus', 'mi', 'eiusmod',
    'nulla', 'maecenas', 'purus', 'congue', 'labore', 'pellentesque', 'aliqua', 'sollicitudin', 'ipsum', 'vel',
    'odio', 'tortor', 'malesuada', 'euismod', 'varius', 'leo', 'interdum', 'pharetra', 'urna', 'volutpat',
    'elementum', 'montes', 'cras', 'nullam', 'facilisi', 'platea', 'ultrices', 'auctor', 'augue', 'tempus',
    'posuere', 'eget', 'consectetur', 'convallis', 'tempor', 'magnis', 'venenatis', 'hac', 'pretium', 'feugiat',
    'proin', 'mattis', 'do', 'morbi', 'ac', 'netus', 'quam', 'nibh', 'non', 'porta', 'cursus', 'dolor', 'diam',
    'quisque', 'consequat', 'tincidunt', 'aliquam', 'nascetur', 'sit', 'dictumst', 'turpis', 'mollis', 'dolore',
    'fames', 'fermentum', 'parturient', 'viverra', 'in', 'phasellus', 'bibendum', 'etiam', 'rutrum', 'sagittis',
    'porttitor', 'id', 'nam', 'velit', 'dis', 'massa', 'sapien', 'egestas', 'sed', 'ligula', 'amet', 'habitasse',
    'scelerisque', 'aenean', 'nisl', 'quis', 'mauris', 'adipiscing', 'ut', 'nisi', 'accumsan', 'est', 'nunc',
    'semper', 'et', 'faucibus', 'orci', 'vitae', 'integer', 'condimentum'
]


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
                if isinstance(sv, float) and isinstance(ov, float):
                    if not self.__is_close__(sv, ov):
                        return False
                    continue
                if sv != ov:
                    return False
            return True

        return NotImplemented

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
    

def timeit(fn):
    def wrapper(*args, **kwargs):
        st = perf_counter()
        try:
            return fn(*args, **kwargs)
        finally:
            en = perf_counter()
            logger.debug(f"{fn.__name__} took {round(en - st, 4)}s")

    return wrapper


def run_subprocess(commands: Sequence[str] | str, cwd: Path = "~") -> tuple[bool, str, str]:
    """
    :param cwd: current working directory
    :param commands: commands to run in subshell, sequence of or singular string(s)
    :parm cwd: working directory for subshell
    :returns: status code (True on success, False on error), stdout, stderr
    """
    result = subprocess.run(
        commands,
        cwd=os.path.abspath(os.path.expanduser(cwd)),
        capture_output=True,
        text=True,
    )
    return result.returncode == 0, result.stdout, result.stderr


def euid_is_root() -> bool:
    """Returns True if the current process is effectively running as root."""
    return os.geteuid() == 0


def generate_lorem_ipsum(count: int) -> str:
    txt = "Lorem"
    newline = False
    capitalize = False
    for i in range(count):
        next_token: str = " " + random.choice(LOREM_IPSUM_TOKENS)
        if capitalize:
            next_token = f".\n{random.choice(LOREM_IPSUM_TOKENS).title()}" if newline else f". {random.choice(LOREM_IPSUM_TOKENS).title()}"

        txt += next_token
        newline = bool(randint(1, 2) == 1)
        capitalize = bool(randint(1, 14) == 1)

    return txt + "."


class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    format = "%(levelname)s: %(message)s"

    FORMATS = {
        logging.INFO: "%(message)s " + reset,  # use this for user-facing output
        logging.DEBUG: reset + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


def get_logger() -> logging.Logger:
    # create logger
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    # create console handler with a higher log level
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(CustomFormatter())

    logger.addHandler(ch)
    return logger
