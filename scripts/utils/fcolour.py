#!/usr/bin/env -S python3 -S -OO
from enum import StrEnum
from os import environ
from pathlib import PosixPath
from typing import Callable
from functools import partial

type Colour = str


def __colour_string(text: str, c: Colour):
    return f"\033[{c}m{text}\033[0m"


def __colour_default(p: PosixPath, colour: Colour):
    pass


def __colour_file(p: PosixPath, colour: Colour):
    pass


def __colour_directory(p: PosixPath, colour: Colour):
    pass


def __colour_symlink(p: PosixPath, colour: Colour):
    pass


def __colour_named_pipe(p: PosixPath, colour: Colour):
    pass


def __colour_block(p: PosixPath, colour: Colour):
    pass


def __colour_char(p: PosixPath, colour: Colour):
    pass


def __colour_orphan(p: PosixPath, colour: Colour):
    pass


def __colour_socket(p: PosixPath, colour: Colour):
    pass


def __colour_setuid(p: PosixPath, colour: Colour):
    pass


def __colour_setgid(p: PosixPath, colour: Colour):
    pass


def __colour_sticky_other_writable(p: PosixPath, colour: Colour):
    pass


def __colour_other_writable(p: PosixPath, colour: Colour):
    pass


def __colour_sticky(p: PosixPath, colour: Colour):
    pass


def __colour_exec(p: PosixPath, colour: Colour):
    pass


def __colour_missing(p: PosixPath, colour: Colour):
    pass


def __colour_leftcode(p: PosixPath, colour: Colour):
    pass


def __colour_rightcode(p: PosixPath, colour: Colour):
    pass


def __colour_endcode(p: PosixPath, colour: Colour):
    pass


def colour_path(p: PosixPath):
    try:
        if "." in p.name:
            extl = p.name.split(".")[1:]
            ext = ".".join(extl)
            # FIXME somehow after this, continue with the special keys
            return __extension_colours[ext](p.name)
    except KeyError:
        pass

    # check all special keys and return
    return p.name


# there are more options, but they're undocumented as far as I can tell;
#  we probably have to look into `ls` source code to figure it out
__ls_colors_special_keys = {
    "no": __colour_default,
    "fi": __colour_file,
    "di": __colour_directory,
    "ln": __colour_symlink,
    "pi": __colour_named_pipe,
    "bd": __colour_block,
    "cd": __colour_char,
    "or": __colour_orphan,
    "so": __colour_socket,
    "su": __colour_setuid,
    "sg": __colour_setgid,
    "tw": __colour_sticky_other_writable,
    "ow": __colour_other_writable,
    "st": __colour_sticky,
    "ex": __colour_exec,
    "mi": __colour_missing,
    "lc": __colour_leftcode,
    "rc": __colour_rightcode,
    "ec": __colour_endcode,
}

__special_colours: list[Callable[[str], str]] = []
__extension_colours: dict[str, Callable[[str], str]] = {}

_ls_colors = environ["LS_COLORS"].split(":")
for colour_set in _ls_colors:
    # the last 'set' has a chance to be empty
    if colour_set:
        _key, _colour = colour_set.replace("*", "").split("=")
        if _key.startswith("."):
            __extension_colours[_key] = lambda n: __colour_string(n, _colour)
            continue

        try:
            __special_colours.append(partial(__ls_colors_special_keys[_key], colour=_colour))
        except KeyError:
            # silently ignore errors
            pass
