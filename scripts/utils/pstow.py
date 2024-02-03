#!/usr/bin/env python3.12
import math
import os
from argparse import ArgumentParser
from copy import copy
from pathlib import PosixPath
from typing import Iterable, final, Self, Optional, Callable


class PathError(RuntimeError):
    pass


@final
class PosixPathUtils:
    def __init__(self):
        raise RuntimeError("Cannot instantiate static class!")

    @staticmethod
    def convert_path_str_to_posixpath(p: str, strict=True) -> PosixPath:
        return PosixPath(os.path.expandvars(os.path.expanduser(p))).resolve(strict=strict)

    @staticmethod
    def posixpath_equals(dir1: PosixPath, dir2: PosixPath) -> bool:
        # if their "type" is different rather than the same, definitely doesn't equal
        #  .is_file() is used for convenience, it could be is_dir() for both instead
        if not (dir1.is_file() and dir2.is_file()):
            return False

        # if not on the same depth, doesn't equal
        if len(dir1.parts) != len(dir2.parts):
            return False

        for file_component, dir_component in zip(dir1.parts, dir2.parts):
            if file_component != dir_component:
                return False


# AUTHOR'S NOTE:
# For future refence, a nice refactor would be to move the tree ops outside the class because it's bloated
#  but currently, I do not want to deal with multiple files for this particular project.
#  However, an ops @property, would be the cool way to do it, with a TreeOperator(self) "bridge".
@final
class Tree:
    STOWIGNORE_FN = ".stowignore"

    def __init__(self, tld: PosixPath):
        self.tld: PosixPath = tld.absolute()
        self.__tree: list[Self | PosixPath] = []
        self.stowignore: Optional[PosixPath] = None

    def __eq__(self, other: Self) -> bool:
        """
        Does not check for and branch equality, just the path.
        @param other:
        @return:
        """
        if not isinstance(other, Tree):
            return False
        if self.name != other.name:
            return False

        self_parts = self.absolute.parts
        other_parts = other.absolute.parts
        if len(self_parts) != len(other_parts):
            return False

        for spc, opc in zip(self_parts, other_parts):
            if spc != opc:
                return False

        return True

    @property
    def absolute(self) -> PosixPath:
        # try to not leak obj reference
        return copy(self.tld)

    @property
    def name(self) -> str:
        return self.tld.name

    @property
    def tree(self) -> list[Self | PosixPath]:
        return self.__tree

    @tree.setter
    def tree(self, element: Self | PosixPath):
        # subtree handling
        if isinstance(element, Iterable):
            self.__tree.extend(element)
            return

        self.__tree.append(element)

    @property
    def branches(self) -> Iterable[Self]:
        return filter(lambda el: isinstance(el, Tree), self.tree)

    @property
    def contents(self) -> Iterable[PosixPath]:
        return filter(lambda el: isinstance(el, PosixPath), self.tree)

    def traverse(self) -> Self:
        """
        Traverse the directory tree and populate self.
        @return:
        """
        for current_path, directory_names, file_names in os.walk(self.tld, followlinks=False):
            for dn in directory_names:
                self.tree = Tree(self.tld / dn).traverse()

            for fn in file_names:
                pp = PosixPath(os.path.join(current_path, fn))
                if fn == Tree.STOWIGNORE_FN:
                    self.stowignore = pp
                    continue

                self.tree = pp

        return self

    def dfs(self) -> Iterable[PosixPath]:
        """
        Depth-first search, returns all the contents.
        @return:
        """
        for branch in self.branches:
            yield branch.dfs()
        for pp in self.contents:
            yield PosixPath(self.absolute / pp)
        return

    def rtrim_file(self, element: PosixPath, depth: int = math.inf) -> Self:
        """
        Recursively trim the PosixPath element from the contents.
        Falls back to children if it doesn't exist.
        @param element: Element to be removed
        @param depth: Determines the maximum allowed depth to search. The Default value is infinite.
        @return:
        """
        if depth < 0:
            return self
        if element is None:
            raise RuntimeError(f"Expected PosixPath, got None?!")
        if not isinstance(element, PosixPath):
            raise RuntimeError(f"Expected PosixPath, got {type(element)}")

        contents = self.contents
        removable_contents = list(filter(lambda pp: PosixPathUtils.posixpath_equals(element, pp), contents))
        for rcont in removable_contents:
            removable_contents.remove(rcont)

        if not removable_contents:
            for branch in self.branches:
                branch.rtrim_file(element, depth=depth - 1)

        return self

    def rtrim_branch(self, removable_branch: Self, depth: int = math.inf) -> Self:
        """
        Recursively trim the Tree branch, removing it from the branches.
        Falls back to children if it doesn't exist.
        @param removable_branch:
        @param depth: Determines the maximum allowed depth to search. The Default value is infinite.
        @return:
        """
        if depth < 0:
            return self
        # sanity checks
        if removable_branch is None:
            raise RuntimeError(f"Expected Tree, got None?!")
        if not isinstance(removable_branch, Tree):
            raise RuntimeError(f"Expected Tree, got {type(removable_branch)}")
        if removable_branch == self:
            raise RuntimeError(f"Expected other, got self?!")

        branches = self.branches
        subtrees = list(filter(lambda el: el == removable_branch, branches))
        for subtree in subtrees:
            self.tree.remove(subtree)

        # if we didn't get any matches, the branch wasn't ours to trim, check children
        if not subtrees:
            for branch in branches:
                branch.rtrim_branch(removable_branch, depth=depth - 1)

        return self

    def rtrim_ignored(self, depth: int = math.inf) -> Self:
        """
        Recursively trim all the branches & elements,
        from the existing .stowignore files, in each tld (top-level directory).
        @return:
        """
        if depth < 0:
            return self

        if self.stowignore:
            for ignorable in self.resolve():
                pass

        subtree: Tree
        for subtree in self.branches:
            subtree.rtrim_ignored(depth=depth - 1)

        raise NotImplementedError  # TODO

    def trim_content_rule(self, fn: Callable[[PosixPath, int], bool], depth: int = math.inf) -> Self:
        """
        Apply business rule to contents.
        @param fn: Business function, determines whether the element will be removed or not, with depth provided.
        @param depth: Determines the maximum allowed depth to search. The Default value is infinite.
        @return:
        """
        if depth < 0:
            return self
        raise NotImplementedError  # TODO

    def trim_branch_rule(self, fn: Callable[[Self, int], bool], depth: int = math.inf) -> Self:
        """
        Apply business rule to branches.
        @param fn: Business function, determines whether the element will be removed or not, with depth provided.
        @param depth: Determines the maximum allowed depth to search. The Default value is infinite.
        @return:
        """
        if depth < 0:
            return self
        raise NotImplementedError  # TODO

    @classmethod
    def resolve(cls, tld: PosixPath, stowignore: PosixPath) -> list[Self | PosixPath]:
        """
        Resolve the structure of a .stowignore.
        @param tld: Top-level directory PosixPath
        @param stowignore: PosixPath pointing to a .stowignore.
        """
        # noinspection PyShadowingNames
        def handle_ignore_line(tld: PosixPath, sti_line: str) -> Iterable[PosixPath | Tree]:
            raise NotImplementedError  # TODO

        to_remove: list[Self | PosixPath] = []
        with open(stowignore, "r", encoding="UTF-8") as sti:
            for line in sti:
                trimmed_line = line.strip()
                to_remove.extend(handle_ignore_line(tld, trimmed_line))

        return to_remove


@final
class Stower:
    # noinspection PyShadowingNames
    def __init__(self,
                 source: PosixPath,
                 destination: PosixPath,
                 skippables: list[PosixPath] = None,
                 force=False,
                 ignore_others=False,
                 make_parents=False):
        self.src = source
        self.dest = destination
        self.skippables = skippables  # TODO use

        # empty flags
        self.force = force
        self.overwrite_others = ignore_others
        self.make_parents = make_parents

        # aka working tree directory, reflects the current filesystem structure
        self.src_tree: Tree = Tree(self.src)

    def _prompt(self) -> bool:
        """
        Prompt the user for an input, [Y/n].
        @return:
        """
        while True:
            reply = input("Are you sure you want to continue [Y/n]?").lower()
            if reply != "y" or reply != "n":
                print(f"Invalid reply {reply}, please answer with Y/y for Yes, or N/n for no.")
                continue
            return reply == "y"

    def stow(self):
        """
        @raise PathError: if src and dest are the same
        """
        # first step: create the tree of the entire src folder
        self.src_tree.traverse()
        # second step: trim the tree from top to bottom, for every .stowignore we find, we will apply
        #  the .stowignore rules only to the same-level trees and/or files, hence, provably and efficiently
        #  trimming all useless paths
        self.src_tree.rtrim_ignored()
        # third step: apply extra business rules to the tree (e.g., ignore items owned by other users etc.)
        self.src_tree.trim_content_rule(
            lambda pp, _: False
        )
        self.src_tree.trim_branch_rule(
            lambda br, _: False
        )

        # fourth step: ...

        # TODO: if src is same as dest, abort
        # TODO: if we would overwrite the source by copying a specific link to dest,
        #  abort due to fatal conflict. For example, following src dotfiles structure:
        #  dotfiles
        #    > dotfiles
        #  gets stowed to destination /.../dotfiles/..
        #  the inner dotfiles/dotfiles symlink to dotfiles/.. would overwrite the original,
        #   resulting in a catastrophic failure where everything is borked.


def get_arparser() -> ArgumentParser:
    ap = ArgumentParser(
        "A spiritual reimplementation, perhaps simpler but more verbose, of GNU Stow."
    )
    ap.add_argument(
        "--source", "-s",
        type=str,
        required=True,
        help="Source directory links will be copied from."
    )
    ap.add_argument(
        "--destination", "-d",
        type=str,
        required=True,
        help="Destination directory links will be configured to."
    )
    ap.add_argument(
        "--force", "-f",
        required=False,
        action="store_true",
        default=False,
        help="Force overwite of any conflicting soft links. This will not overwrite regular files."
    )
    ap.add_argument(
        "--loose", "-l",
        required=False,
        action="store_false",
        default=True,
        help="Loose restrictions on source & destination file paths. Will allow symlinks to be resolved."
    )
    ap.add_argument(
        "--exclude", "-e",
        required=False,
        type=str,
        nargs="+",
        action="append",
        default=[],
        help="Exclude (ignore) a specific directory when copying the tree. Multiple values can be given."
             "Symlinks are not supported as exclusion criteria."
    )
    ap.add_argument(
        "--ignore-others", "-i",
        required=False,
        action="store_true",
        default=False,
        help="Ignore links/files owned by other users than the current one."
             "Default behaviour is to not overwrite files not owned by the current user."
             "Functionally the same as --no-preserve-root in the rm command."
    )
    ap.add_argument(
        "--make-parents", "-p",
        required=False,
        action="store_true",
        default=False,
        help="Make parent directories as we traverse the tree in destination, if they do not exist."
    )

    return ap


if __name__ == "__main__":
    args = get_arparser().parse_args()
    try:
        src = PosixPathUtils.convert_path_str_to_posixpath(args.source, strict=not args.loose)
        dest = PosixPathUtils.convert_path_str_to_posixpath(args.destination, strict=not args.loose)
        excluded = [
            PosixPathUtils.convert_path_str_to_posixpath(str_path, strict=not args.loose) for str_path in args.exclude
        ]
        force = args.force
        io = args.ignore_others
        mp = args.make_parents

        Stower(
            src, dest,
            skippables=excluded,
            force=force,
            ignore_others=io,
            make_parents=mp,
        ).stow()
    except FileNotFoundError as e:
        print(f"Couldn't find file!\n{e}")
    except PathError as e:
        print(f"Invalid operation PathError!\n{e}")
