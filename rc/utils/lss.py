#!/usr/bin/env -S python3 -S
from enum import Enum
from sys import argv, stderr, exit
from pathlib import PosixPath
from subprocess import run
from fcolour import colour
from functools import reduce
import typing


class UnicodeGirderChars(Enum):
    TOP_START_SYMBOL = "┌"
    TOP_JOIN_SYMBOL = "┬"
    TOP_END_SYMBOL = "┐"

    ROW_SYMBOL = "─"

    BOT_START_SYMBOL = "└"
    BOT_JOIN_SYMBOL = "┴"
    BOT_END_SYMBOL = "┘"


class Column:
    def __init__(self, elements: list[PosixPath] = None, subcolumns: list = None):
        if subcolumns is None:
            subcolumns = []
        if elements is None:
            elements = []

        self.subcolumns: list = subcolumns
        self.elements: list[PosixPath] = elements
        self.max = 0
        for e in elements:
            self.max = max(self.max, len(str(e.name)))

    def get_col_indices(self) -> list[int]:
        subc_maxes = []
        for subc in self.subcolumns:
            subc_maxes.append(*subc.get_col_indices())
        return [self.max, *subc_maxes]

    def get_row_indices(self) -> list[int]:
        subc_maxes = []
        for subc in self.subcolumns:
            subc_maxes.append(*subc.get_row_indices())
        return [len(self.elements), *subc_maxes]

    def size(self) -> int:
        return len(self.elements)

    def get_row_elements(self, max_cols, max_lines):
        subgenerators: Typing.Generator = []
        for sub in self.subcolumns:
            subgenerators.append(sub.get_row_elements(max_cols // len(self.subcolumns), max_lines))
        total_rows = reduce(lambda x, y: x + y, self.get_row_indices())
        columns = (total_rows // max_lines) + 1
        rows = (total_rows // columns) + (total_rows % columns)

        element_index = 0
        for i in range(rows):
            line = ""
            line_overhead = 0

            for j in range(columns):
                if element_index < len(self.elements):
                    word, overhead = colour(self.elements[element_index])
                    line += word + " " * (self.max - len(word) + overhead)
                    line_overhead += overhead
                    element_index += 1

            for subg in subgenerators:
                try:
                    word, overhead = next(subg)
                    line_overhead += overhead
                    line += word
                except StopIteration:
                    pass

            yield line, line_overhead


def run_subshell(command: list[str]) -> tuple[int, str]:
    res = run(command, capture_output=True, encoding="utf-8")
    return res.returncode, res.stdout


def git_status(directory: str):
    git_status = ""
    toplevel = run_subshell(["git", "-C", directory, "rev-parse", "--show-toplevel"])[1]

    if toplevel:
        git_status = "Working tree clean."
        changes = run_subshell(["git", "-C", directory, "status", "-s", "--ignored=no"])[1]
        if changes:
            git_status = "Uncommited changes."

    return git_status


def term_size() -> tuple[int, int]:
    lines = run(["tput", "lines"], capture_output=True, encoding="utf-8").stdout.replace("\n", "")
    cols = run(["tput", "cols"], capture_output=True, encoding="utf-8").stdout.replace("\n", "")
    return int(lines), int(cols)


def get_all_elements(directory: PosixPath) -> tuple[list[PosixPath], list[PosixPath]]:
    elements = directory.glob("*")
    dirs = []
    files = []
    for e in elements:
        if e.is_dir():
            dirs.append(e)
            continue

        files.append(e)
    return dirs, files


if __name__ == "__main__":
    cwd = PosixPath.cwd()
    if len(argv) > 1:
        cwd = PosixPath(argv[1])

    pcwd = PosixPath(cwd)
    if not pcwd.is_dir():
        print(f"\"{cwd}\" is not a directory, or not enough permissions.", file=stderr)
        exit(2)

    term_lines, term_cols = term_size()
    dirs, files = get_all_elements(cwd)
    dirs.sort()
    files.sort()

    dir_column = Column(elements=dirs)
    files_column = Column(elements=files)
    output_column = Column(subcolumns=[dir_column, files_column])

    print(f"{len(dirs)} directories, {len(files)} files. {git_status(str(cwd))}")
    if len(dirs) == 0 and len(files) == 0:
        exit(0)

    for line in output_column.get_row_elements(term_cols, term_lines - 3):
        row: str = line[0]
        overhead: int = line[1]
        if not row:
            exit(0)
        print(row[:term_cols + overhead])

    # for line in output_column.get_line(max_cols=term_cols, max_lines=term_lines, wrap=True):
    #     print(line[0])

    # print(pcwd)
    # print(colour(cwd))

    #
    #
