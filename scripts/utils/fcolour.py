#!/usr/bin/env -S python3 -S -OO
from enum import StrEnum
from pathlib import PosixPath
from os import set_blocking
from os import environ
import re

class EscapeCodes(StrEnum):
    PREFIX = "\033["


class Colours(StrEnum):
    NOCOLOUR = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"
    BLINK = "\033[5m"


def colour_string(text: str, colour: tuple[Colours: str]):
    return f"{''.join(colour)}{text}{Colours.NOCOLOUR}"


def colour(p: PosixPath):
    try:
        if "." in p.name:
            extl = p.name.split(".")[1:]
            ext = ".".join(extl)
            return __extension_colours[ext](p)
    except KeyError:
        pass

    return p.name


__extension_colours: dict[str, str] = {}

file_color_regex = re.compile(r"\.[a-zA-Z0-9\-_]+=[0-9]{1,3}[;0-9]{0,3}")
for result in file_color_regex.finditer(environ["LS_COLORS"]):
    
    result_str = result.group()
    _extension = re.findall(r"[a-zA-Z0-9\-_]+", result_str)[0]
    _colour = re.findall(r"[0-9]{1,3}[;0-9]{0,3}", result_str)[-1]
    
    __extension_colours[_extension] = lambda p: colour_string(p.name, (f"{EscapeCodes.PREFIX}{_colour}m"))
