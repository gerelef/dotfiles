#!/usr/bin/env -S python3 -S -OO
from math import floor
from pathlib import PosixPath
from subprocess import run
from sys import argv, stderr, exit
from typing import Iterator

from fcolour import colour, Colours


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

    def __len__(self) -> int:
        """Count of elements."""
        return len(self.elements)

    def get_ideal_rows_columns(self, mc, ml, tr) -> tuple[int, int]:
        columns = floor(tr / ml) + 1
        rows = ml + (tr % columns)
        return columns, rows

    def get_row_elements(self, max_cols, max_lines) -> Iterator[tuple[str, int]]:
        columns, rows = self.get_ideal_rows_columns(max_cols, max_lines, max(self.get_row_indices()))

        subgenerators = []
        for sub in self.subcolumns:
            subgenerators.append(sub.get_row_elements(max_cols, max_lines))

        element_index = 0
        for i in range(rows):
            line = ""
            # this is essentially padding
            line_overhead = 1

            for j in range(columns):
                word = ""
                if element_index < len(self.elements):
                    word_temp, overhead = colour(self.elements[element_index])
                    word += word_temp

                    line += word + Colours.NOCOLOUR + " " * (self.max - len(word) + overhead)
                    line_overhead += overhead
                    element_index += 1
                else:
                    # pad the row if not enough elements to fill the column
                    line += " " * self.max

            for subg in subgenerators:
                word, overhead = next(subg)
                line_overhead += overhead
                line += word

            yield line, line_overhead

        # return only padded elements if they keep asking for more...
        while True:
            yield " " * self.max * columns, 0


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


def term_size() -> tuple[int, int]:
    # if for some reason the terminal tput cols/lines doesn't work, return 0, so we can at least *not* crash.
    lines = run(["tput", "lines"], capture_output=True, encoding="utf-8").stdout.replace("\n", "") or 0
    cols = run(["tput", "cols"], capture_output=True, encoding="utf-8").stdout.replace("\n", "") or 0
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
    cwd = PosixPath(argv[1]) if len(argv) > 1 else PosixPath(PosixPath.cwd())

    if not cwd.is_dir():
        print(f"\"{cwd}\" is not a directory, or not enough permissions.", file=stderr)
        exit(2)

    term_lines, term_cols = term_size()
    dirs, files = get_all_elements(cwd)
    dirs.sort()
    files.sort()

    dir_column = Column(elements=dirs)
    files_column = Column(elements=files)
    output_column = Column(subcolumns=[dir_column, files_column])

    print(f"{top_level_string(len(dirs), len(files))}. {git_status(str(cwd))}")
    if len(dirs) == 0 and len(files) == 0:
        exit(0)

    for line in output_column.get_row_elements(term_cols, term_lines - 3):
        row: str = line[0]
        overhead: int = line[1]
        if not row or row.isspace():
            exit(0)
        print(row[:term_cols + overhead])
