#!/usr/bin/env -S python3 -S -OO
import os
from functools import partial
from os import environ
from pathlib import PosixPath
from typing import Callable, Iterator, Self

type Colour = str
type PosixColouredString = PosixColouredString


# noinspection PyRedeclaration
class PosixColouredString:
    def __init__(self, text: str, colour_codes: str = "", appendix: str = ""):
        self.colour = colour_codes
        self.string = text
        self.appendix = appendix

        if not isinstance(self.string, str):
            raise RuntimeError("self.string not string?!")

        if not isinstance(self.colour, str):
            raise RuntimeError("self.colour not string?!")

    def crop(self, length):
        if len(self.string) < length:
            return

        if len(self.string) > 6:
            self.string = self.string[0:length - 3] + "..."
            return

        self.string = self.string[0:length]

    def append(self, appendix: str):
        self.appendix = appendix

    def __add__(self, other: PosixColouredString) -> Self:
        if not isinstance(other, PosixColouredString):
            raise RuntimeError(f"Cannot add PosixColouredString and {type(other)}")
        if other.string != self.string:
            raise RuntimeError(f"Cannot add PosixColouredStrings with different strings!")
        if other.appendix != self.appendix:
            raise RuntimeError(f"Cannot add PosixColouredStrings with different appendices!")

        self.colour += other.colour
        return self

    def __len__(self) -> int:
        return len(self.string)

    def __str__(self) -> str:
        if self.colour:
            return f"\033[{self.colour}m{self.string}\033[0m{self.appendix}"

        return f"{self.string}{self.appendix}"


def __colour_string(text: str, c: Colour) -> PosixColouredString:
    return PosixColouredString(text, c)


def __colour_default(p: PosixPath, colour: Colour):
    return __colour_string(p.name, colour)


def __colour_file(p: PosixPath, colour: Colour):
    c = colour if p.is_file() else ""
    return __colour_string(p.name, c)


def __colour_directory(p: PosixPath, colour: Colour):
    c = colour if p.is_dir() else ""
    return __colour_string(p.name, c)


def __colour_symlink(p: PosixPath, colour: Colour):
    c = colour if p.is_symlink() else ""
    return __colour_string(p.name, c)


def __colour_named_pipe(p: PosixPath, colour: Colour):
    c = colour if p.is_fifo() else ""
    return __colour_string(p.name, c)


def __colour_block(p: PosixPath, colour: Colour):
    c = colour if p.is_block_device() else ""
    return __colour_string(p.name, c)


def __colour_char(p: PosixPath, colour: Colour):
    c = colour if p.is_char_device() else ""
    return __colour_string(p.name, c)


def __colour_orphan(p: PosixPath, colour: Colour):
    c = colour if p.is_symlink() and not p.readlink().exists() else ""
    return __colour_string(p.name, c)


def __colour_socket(p: PosixPath, colour: Colour):
    c = colour if p.is_socket() else ""
    return __colour_string(p.name, c)


def __colour_setuid(p: PosixPath, colour: Colour):
    c = colour if p.lstat().st_uid == os.getuid() else ""
    return __colour_string(p.name, c)


def __colour_setgid(p: PosixPath, colour: Colour):
    c = colour if p.lstat().st_gid == os.getgid() else ""
    return __colour_string(p.name, c)


def __colour_sticky_other_writable(p: PosixPath, colour: Colour):
    is_sticky = p.lstat().st_mode & 0o1000
    is_other_writable = p.lstat().st_mode & 0o002
    c = colour if is_sticky and is_other_writable else ""
    return __colour_string(p.name, c)


def __colour_other_writable(p: PosixPath, colour: Colour):
    is_not_sticky = not p.lstat().st_mode & 0o1000
    is_other_writable = p.lstat().st_mode & 0o002
    c = colour if is_not_sticky and is_other_writable else ""
    return __colour_string(p.name, c)


def __colour_sticky(p: PosixPath, colour: Colour):
    is_sticky = p.lstat().st_mode & 0o1000
    is_not_other_writable = not p.lstat().st_mode & 0o002
    c = colour if is_sticky and not is_not_other_writable else ""
    return __colour_string(p.name, c)


def __colour_exec(p: PosixPath, colour: Colour):
    is_executable = p.lstat().st_mode & 0o100
    c = colour if is_executable else ""
    return __colour_string(p.name, c)


def __colour_missing(p: PosixPath, colour: Colour):
    return __colour_string(p.name, "")  # FIXME


def __colour_leftcode(p: PosixPath, colour: Colour):
    return __colour_string(p.name, "")  # FIXME


def __colour_rightcode(p: PosixPath, colour: Colour):
    return __colour_string(p.name, "")  # FIXME


def __colour_endcode(p: PosixPath, colour: Colour):
    return __colour_string(p.name, "")  # FIXME


def __cascade_specials(p: PosixPath, specials_iterator: Iterator):
    pcs = PosixColouredString(p.name)
    for _, fn in specials_iterator:
        pcs = pcs + fn(p)

    return pcs


def colour_path(p: PosixPath) -> PosixColouredString:
    pcs = PosixColouredString(p.name)
    try:
        if "." in p.name:
            extl = p.name.split(".")[1:]
            ext = ".".join(extl)
            pcs += __extension_colour_functions[ext](p.name)
    except KeyError:
        pass

    # check all special keys and return the end value
    return pcs + __cascade_specials(p, enumerate(__special_colour_functions))


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

__special_colour_functions: list[Callable[[str], PosixColouredString]] = []
__extension_colour_functions: dict[str, Callable[[str], PosixColouredString]] = {}

try:
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
                # silently ignore keys we do not support
                pass
except KeyError:
    # something's up and LS_COLORS doesn't exist; ignore silently, it's just visuals
    pass
