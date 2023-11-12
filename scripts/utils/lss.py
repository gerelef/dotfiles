#!/usr/bin/env -S python3 -S -OO
import sys
from math import floor, ceil
from pathlib import PosixPath
from subprocess import run
from sys import argv, stderr, exit
from typing import Iterator

from fcolour import colour, Colours


class Formatter:
    # spaces inbetween columns
    PADDING = 1
    TOLERANCE = .10

    def __init__(self, directories: list[PosixPath], files: list[PosixPath]):
        self.directories = directories
        self.files = files

        self.max_directories_word_length = len(max(directories, key=lambda e: len(e.name)).name) if directories else 0
        self.max_files_word_length = len(max(files, key=lambda e: len(e.name)).name) if files else 0

    def get_ideal_elements_per_line(self, element_count: int, element_size: int) -> int | None:
        """
        :returns: elements per line
        """
        terminal_lines, terminal_columns = Formatter.term_size()

        # minimum WORD columns needed to display everything inside the terminal viewport
        min_word_columns_needed = ceil(element_count / terminal_lines)

        # max WORD columns with the max name length (+ inbetween padding) that fit inside the terminal viewport
        max_word_columns_fitting = floor(terminal_columns / (element_size + Formatter.PADDING))

        # minimum TERMINAL columns needed
        min_terminal_columns_needed = ceil(
            element_size * min_word_columns_needed + Formatter.PADDING * min_word_columns_needed
        )

        if min_word_columns_needed > max_word_columns_fitting:
            return max_word_columns_fitting

        if floor(terminal_lines / 2) <= element_count and (min_word_columns_needed + 1) <= max_word_columns_fitting:
            return min_word_columns_needed + 1

        return min_word_columns_needed

    def output(self) -> Iterator[str | None]:
        # https://stackoverflow.com/questions/2414667/python-string-class-like-stringbuilder-in-c
        max_element_size = max(self.max_files_word_length, self.max_directories_word_length)
        elements_per_line = self.get_ideal_elements_per_line(
            len(self.files) + len(self.directories),
            max_element_size
        )

        current_iterable = self.directories + self.files

        while True:
            if not current_iterable:
                break

            line: list[str] = []
            for _ in range(elements_per_line):
                element = current_iterable.pop(0)
                line.append(colour(element) + ' ' * (max_element_size - len(element.name)))

                if not current_iterable:
                    break

            yield ' '.join(line)

    @staticmethod
    def term_size() -> tuple[int, int]:
        # if for some reason the terminal tput cols/lines doesn't work, return 0, so we can at least *not* crash.
        lines = run(["tput", "lines"], capture_output=True, encoding="utf-8").stdout.replace("\n", "") or 0
        cols = run(["tput", "cols"], capture_output=True, encoding="utf-8").stdout.replace("\n", "") or 0
        # -1 for padding
        return int(lines) - 1, int(cols) - 1


def run_subshell(command: list[str]) -> tuple[int, str]:
    res = run(command, capture_output=True, encoding="utf-8")
    return res.returncode, res.stdout


def top_level_string(directory_count, file_count) -> str:
    directory_cnt_str = f"{directory_count if directory_count > 0 else 'No'}"
    directory_desc_str = f"{'directories' if directory_count != 1 else 'directory'}"
    directory_str = "{}"
    file_cnt_str = f"{file_count if file_count > 0 else 'no'}"
    file_desc_str = f"{'files' if file_count != 1 else 'file'}"
    return f"{directory_cnt_str} {directory_desc_str}, {file_cnt_str} {file_desc_str}"


def git_status(directory: str):
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
    cwd = PosixPath(argv[1]) if len(argv) > 1 else PosixPath(PosixPath.cwd())

    if not cwd.is_dir():
        print(f"\"{cwd}\" is not a directory, or not enough permissions.", file=stderr)
        exit(2)

    dirs, files = get_all_elements_sorted(cwd)
    formatter = Formatter(dirs, files)

    print(f"{top_level_string(len(dirs), len(files))}. {git_status(str(cwd))}")
    if len(dirs) == 0 and len(files) == 0:
        exit(0)

    rows, cols = Formatter.term_size()
    if rows < 10 and cols < 20:
        # not enough space, exit gracefully
        exit(0)

    for s in formatter.output():
        print(s, file=sys.stdout)
