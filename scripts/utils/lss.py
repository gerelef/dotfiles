#!/usr/bin/env -S python3 -S -OO
from math import floor
from pathlib import PosixPath
from stat import filemode
from subprocess import run
from sys import argv, stderr, exit

from fcolour import colour, Colours


class Column:
    def __init__(self, elements: list[PosixPath] = None, subcolumns: list = None, permissions=False):
        if subcolumns is None:
            subcolumns = []
        if elements is None:
            elements = []
        self.subcolumns: list = subcolumns
        self.elements: list[PosixPath] = elements
        self.permissions = permissions
        self.max = 0
        for e in elements:
            if permissions:
                self.max = max(self.max, len(str(e.name)) + len(self.get_permission(e)))
                continue
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

    def get_ideal_rows_columns(self, mc, ml, tr) -> tuple[int, int]:
        columns = floor(tr / ml) + 1
        rows = ml + (tr % columns)
        return columns, rows

    def get_permission(self, pp: PosixPath):
        return filemode(pp.lstat().st_mode)

    def get_row_elements(self, max_cols, max_lines):
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
                    if self.permissions:
                        word = self.get_permission(self.elements[element_index]) + " "
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


def git_status(directory: str):
    status = "Working tree clean."
    ret_code, toplevel = run_subshell(["git", "-C", directory, "rev-parse", "--show-toplevel"])

    # not a git directory most likely
    if ret_code != 0:
        return ""

    if toplevel:
        _, has_changes = run_subshell(["git", "-C", directory, "status", "-s", "--ignored=no"])
        if has_changes:
            status = "Uncommited changes."

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
    permissions = False

    cwd = PosixPath(argv[1]) if len(argv) > 1 else PosixPath(PosixPath.cwd())

    if not cwd.is_dir():
        print(f"\"{cwd}\" is not a directory, or not enough permissions.", file=stderr)
        exit(2)

    term_lines, term_cols = term_size()
    dirs, files = get_all_elements(cwd)
    dirs.sort()
    files.sort()

    dir_column = Column(elements=dirs, permissions=permissions)
    files_column = Column(elements=files, permissions=permissions)
    output_column = Column(subcolumns=[dir_column, files_column], permissions=permissions)

    print(f"{len(dirs)} directories, {len(files)} files. {git_status(str(cwd))}")
    if len(dirs) == 0 and len(files) == 0:
        exit(0)

    for line in output_column.get_row_elements(term_cols, term_lines - 3):
        row: str = line[0]
        overhead: int = line[1]
        if not row or row.isspace():
            exit(0)
        print(row[:term_cols + overhead])
