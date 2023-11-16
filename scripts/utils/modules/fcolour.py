#!/usr/bin/env -S python3 -S -OO
from functools import partial
from os import environ
from pathlib import PosixPath
from typing import Callable, Iterator

type Colour = str


def __colour_string(text: str, c: Colour):
    return f"\033[{c}m{text}\033[0m" if c else text


def __colour_default(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_file(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_directory(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_symlink(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_named_pipe(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_block(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_char(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_orphan(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_socket(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_setuid(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_setgid(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_sticky_other_writable(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_other_writable(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_sticky(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_exec(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_missing(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_leftcode(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_rightcode(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_endcode(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __cascade_specials(p: PosixPath, specials_iterator: Iterator):
    try:
        _, fn = next(specials_iterator)
        return fn(p)
    except StopIteration:
        return ""


def colour_path(p: PosixPath):
    try:
        if "." in p.name:
            extl = p.name.split(".")[1:]
            ext = ".".join(extl)
            # FIXME somehow after this, continue with the special keys
            return __extension_colour_functions[ext](p.name)
    except KeyError:
        pass

    # check all special keys and return
    return __cascade_specials(p, enumerate(__special_colour_functions))


# there are more options, but they're undocumented as far as I can tell;
#  we probably have to look into `ls` source code to figure it out
# http://www.bigsoft.co.uk/blog/2008/04/11/configuring-ls_colors
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

__special_colour_functions: list[Callable[[str], str]] = []
__extension_colour_functions: dict[str, Callable[[str], str]] = {}

_ls_colors = environ["LS_COLORS"].split(":")
for colour_set in _ls_colors:
    # the last 'set' has a chance to be empty
    if colour_set:
        _key, _colour = colour_set.replace("*", "").split("=")
        if _key.startswith("."):
            __extension_colour_functions[_key] = lambda n: __colour_string(n, _colour)
            continue

        try:
            __special_colour_functions.append(
                partial(
                    __ls_colors_special_keys[_key], colour=_colour
                )
            )
        except KeyError:
            # silently ignore errors
            pass
