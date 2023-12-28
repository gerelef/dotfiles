#!/usr/bin/env -S python3 -S -OO
import os
import sys
from math import floor, ceil
from pathlib import PosixPath
from stat import S_ISFIFO
from subprocess import run
from sys import argv, exit
from typing import Iterator

from modules.fcolour import colour_path, PosixColouredString


class Formatter:
    # spaces inbetween columns
    PADDING = 1

    def __init__(self, directories: list[PosixPath], files: list[PosixPath]):
        self.directories = directories
        self.files = files

        self.terminal_lines, self.terminal_columns = Formatter.term_size()

        self.max_directories_word_length = len(max(directories, key=lambda e: len(e.name)).name) if directories else 0
        self.max_files_word_length = len(max(files, key=lambda e: len(e.name)).name) if files else 0

    def get_ideal_elements_per_line(self, element_count: int, max_element_size: int) -> int | None:
        """
        :returns: elements per line
        """
        # minimum WORD lines needed to display everything inside the terminal viewport
        min_word_lines_needed = ceil(element_count / self.terminal_lines)

        # max WORD columns with the max name length (+ inbetween padding) that fit inside the terminal viewport
        max_word_columns_fitting = floor(self.terminal_columns / (max_element_size + Formatter.PADDING))

        # minimum TERMINAL columns needed
        min_terminal_columns_needed = ceil(
            max_element_size * min_word_lines_needed + Formatter.PADDING * min_word_lines_needed
        )

        # if the minimum word lines we need to display everything are more
        #  than the maximum word columns that fit, and at least one column fits (> 0)
        if min_word_lines_needed > max_word_columns_fitting > 0:
            return max_word_columns_fitting

        columns_can_overfit = floor(self.terminal_lines / 2) <= element_count
        overfit_wont_overflow = (min_word_lines_needed + 1) <= max_word_columns_fitting
        if columns_can_overfit and overfit_wont_overflow:
            return min_word_lines_needed + 1

        return min_word_lines_needed

    def output(self) -> Iterator[str | None]:
        # https://stackoverflow.com/questions/2414667/python-string-class-like-stringbuilder-in-c
        # if the elements won't fit at all, we'll make them fit with .crop() on our own anyways
        max_element_size = min(
            max(self.max_files_word_length, self.max_directories_word_length),
            self.terminal_columns
        )

        elements_per_line = self.get_ideal_elements_per_line(
            len(self.files) + len(self.directories),
            max_element_size
        )

        current_iterable = self.directories + self.files

        while True:
            if not current_iterable:
                break

            line: list[PosixColouredString] = []
            for _ in range(elements_per_line):
                element = current_iterable.pop(0)
                out = colour_path(element)
                out.crop(self.terminal_columns)
                out.append(' ' * (max_element_size - len(element.name)))

                line.append(out)

                if not current_iterable:
                    break

            yield ' '.join(map(str, line))

    @staticmethod
    def term_size() -> tuple[int, int]:
        if "LINES" not in os.environ or "COLUMNS" not in os.environ:
            if not is_debugging():
                print("$LINES and/or $COLUMNS are NOT defined in the environment!", file=sys.stderr)
                print("For regular use, you might need to export LINES && export COLUMNS.", file=sys.stderr)
                print("For developer work, run with a debugger active.", file=sys.stderr)
                exit(1)

            # debug lines/columns
            return 15, 90

        return int(os.environ["LINES"]), int(os.environ["COLUMNS"])


# https://stackoverflow.com/a/71527398
def is_debugging() -> bool:
    return (gettrace := getattr(sys, 'gettrace')) and gettrace()


def top_level_string(directory_count, file_count) -> str:
    directory_cnt_str = f"{directory_count if directory_count > 0 else 'No'}"
    directory_desc_str = f"{'directories' if directory_count != 1 else 'directory'}"
    file_cnt_str = f"{file_count if file_count > 0 else 'no'}"
    file_desc_str = f"{'files' if file_count != 1 else 'file'}"
    return f"{directory_cnt_str} {directory_desc_str}, {file_cnt_str} {file_desc_str}"


def git_status(directory: str):
    def run_subshell(command: list[str]) -> tuple[int, str]:
        res = run(command, capture_output=True, encoding="utf-8")
        return res.returncode, res.stdout

    status = "Working tree clean."
    ret_code, toplevel = run_subshell(["git", "-C", directory, "rev-parse", "--show-toplevel"])

    # not a git directory most likely
    if ret_code != 0:
        return ""

    if toplevel:
        _, has_changes = run_subshell(["git", "-C", directory, "status", "-s", "--ignored=no"])
        if has_changes:
            status = "Uncommitted changes."

    return status


def get_all_elements_sorted(directory: PosixPath) -> tuple[list[PosixPath], list[PosixPath]]:
    elements = directory.glob("*")
    dirs = []
    files = []
    for e in elements:
        if e.is_dir():
            dirs.append(e)
            continue

        files.append(e)

    dirs.sort()
    files.sort()
    return dirs, files


if __name__ == "__main__":
    # AUTHORS NOTE:
    # for some godforsaken reason I do not want to know about, cwd.is_dir("~") is FALSE
    # when running it from the IDE, however it's TRUE if we run it from a login shell
    # there is no conceivable universe where this makes sense, and is likely a bug from the fact
    # that (to my knowledge) the current IDE running configuration doesn't inhreit from the login shell
    # however it still doesn't make sense, because cwd.expanduser().is_dir() has the correct effect regardless
    # whether we're running it from the IDE or not.
    # While running this block of text, I realized that it's likely that bash automatically substitutes ~
    # for /home/username, and this is what caused the error
    # consider this a warning to anyone handling paths and expecting everything to be sane, I will have to
    # recheck any script I have that handles paths now. great!
    cwd = PosixPath(argv[1]).expanduser() if len(argv) > 1 else PosixPath.cwd()
    if not cwd.is_dir():
        print(f"\"{cwd}\" is not a directory, or not enough permissions.", file=sys.stderr)
        exit(2)

    dirs, files = get_all_elements_sorted(cwd)
    formatter = Formatter(dirs, files)

    print(f"{top_level_string(len(dirs), len(files))}. {git_status(str(cwd))}", file=sys.stdout)
    if len(dirs) == 0 and len(files) == 0:
        exit(0)

    rows, cols = Formatter.term_size()
    if rows < 15 and cols < 60:
        # not enough space, exit gracefully
        exit(0)

    for s in formatter.output():
        print(s, file=sys.stdout)
