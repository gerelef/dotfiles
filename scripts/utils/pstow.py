#!/usr/bin/env -S python3.12 -S -OO
# From the documentation:
# >"If the readline module was loaded,
#  then input() will use it to provide elaborate line editing and history features."
# noinspection PyUnresolvedReferences
import readline
import getpass
import math
import os
from argparse import ArgumentParser
from copy import copy
from glob import iglob
from pathlib import PosixPath
from typing import Iterable, final, Self, Optional, Callable, Iterator


class PathError(RuntimeError):
    pass


# AUTHOR'S NOTE:
# For future refence, a nice refactor would be to move the tree ops outside the class because it's bloated
#  but currently, I do not want to deal with multiple files for this particular project.
#  However, an ops @property would be the cool way to do it, with a TreeOperator(self) "bridge".
# Recursive-trim functions do not affect the filesystem, they just remove them from the tree.
@final
class Tree:
    STOWIGNORE_FN = ".stowignore"

    def __init__(self, tld: PosixPath):
        self.__tld: PosixPath = tld.absolute()
        self.__tree: list[Self | PosixPath] = []
        self.__stowignore: Optional[PosixPath] = None

    def __eq__(self, other: Self) -> bool:
        """
        Does not check for content and branch equality, just path equality.
        """
        if not isinstance(other, Tree):
            return False
        if self.name != other.name:
            return False

        self_parts = self.absolute.parts
        other_parts = other.absolute.parts
        if len(self_parts) != len(other_parts):
            return False

        # reverse components, since the tail is the one most likely to be different
        for spc, opc in zip(self_parts[::-1], other_parts[::-1]):
            if spc != opc:
                return False

        return True

    def __ne__(self, other: Self) -> bool:
        """
        Inverse equality.
        """
        return not self == other

    def __contains__(self, item: Self | PosixPath):
        self_parts, self_parts_len = PosixPathUtils.get_fs_parts_len(self.absolute)
        if isinstance(item, Tree):
            other_parts, other_parts_len = PosixPathUtils.get_fs_parts_len(item.absolute)
        else:
            other_parts, other_parts_len = PosixPathUtils.get_fs_parts_len(item.absolute())

        # regular zip, not in reverse, since the other_parts might be in a subdirectory,
        #  we just want to check if the tld equivalent is us
        for spc, opc in zip(self_parts, other_parts):
            if spc != opc:
                return False

        return True

    def __repr__(self) -> str:
        return str(self.absolute)

    def __str__(self) -> str:
        # we're doing bfs essentially here, which makes sense in terms of output if you think about it
        out: list[str] = [
            f"{" " * len(self.absolute.parts)}\033[96m\033[1m├>{repr(self)}\033[0m"
        ]
        for content in self.contents:
            out.append(f"{" " * len(self.absolute.parts)}\033[96m│ \033[93m> {str(content.absolute())}\033[0m")
        for branch in self.branches:
            out.append(str(branch))
        return "\n".join(out)

    @property
    def stowignore(self) -> Optional[PosixPath]:
        return self.__stowignore

    @property
    def absolute(self) -> PosixPath:
        """
        @return: Shallow copy of top-level directory, a PosixPath.
        """
        # try to not leak obj reference
        return copy(self.__tld)

    @property
    def name(self) -> str:
        return self.__tld.name

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
        """
        Filter all the branches (subtrees) from the children, and return the iterator.
        """
        return filter(lambda el: isinstance(el, Tree), self.tree)

    @property
    def contents(self) -> Iterable[PosixPath]:
        """
        Filter all the contents (PosixPaths) from the children, and return the iterator.
        """
        return filter(lambda el: isinstance(el, PosixPath), self.tree)

    def traverse(self) -> Self:
        """
        Traverse the directory tree and populate self.
        """
        # the reason for this ugliness, is that os.walk is recursive by nature,
        #  and we do not want to recurse by os.walk, but rather by child.traverse() method
        current_path, directory_names, file_names = next(os.walk(self.absolute, followlinks=False))
        for fn in file_names:
            pp = PosixPath(os.path.join(current_path, fn))
            if fn == Tree.STOWIGNORE_FN:
                self.__stowignore = pp

            self.tree = pp

        for dn in directory_names:
            self.tree = Tree(self.absolute / dn).traverse()

        return self

    def dfs(self) -> Iterable[PosixPath]:
        """
        Depth-first search, returns all the contents, bottom to top.
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
        @param depth: Determines the maximum allowed depth to search.
        The default value is infinite.
        """
        if depth < 0:
            return self
        if element is None:
            raise RuntimeError(f"Expected PosixPath, got None?!")
        if not isinstance(element, PosixPath):
            raise RuntimeError(f"Expected PosixPath, got {type(element)}")

        contents = self.contents
        removable_contents: Iterable[PosixPath] = filter(lambda pp: PosixPathUtils.posixpath_equals(element, pp),
                                                         contents)
        for rcont in removable_contents:
            # edge case for stowignore files:
            if rcont.name == Tree.STOWIGNORE_FN:
                self.__stowignore = None

            self.tree.remove(rcont)

        # early exit
        if removable_contents:
            return self

        # if we didn't get any matches, the file wasn't ours to trim, check children
        for branch in self.branches:
            branch.rtrim_file(element, depth=depth - 1)

        return self

    def rtrim_branch(self, removable_branch: Self, depth: int = math.inf) -> Self:
        """
        Recursively trim the Tree branch, removing it from the branches.
        Falls back to children if it doesn't exist.
        @param removable_branch:
        @param depth: Determines the maximum allowed depth to search.
        The default value is infinite.
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

        # early exit
        if subtrees:
            return self

        for branch in branches:
            branch.rtrim_branch(removable_branch, depth=depth - 1)

        return self

    def rtrim_ignored(self, depth: int = math.inf) -> Self:
        """
        Recursively trim all the branches & elements,
        from the existing .stowignore files, in each tld (top-level directory).
        @param depth: Determines the maximum allowed depth to search.
        The default value is infinite.
        """
        if depth < 0:
            return self

        if self.stowignore:
            for ignorable in self.resolve(self.absolute, self.stowignore):
                if isinstance(ignorable, Tree):
                    self.rtrim_branch(ignorable, depth=depth)
                    continue

                self.rtrim_file(ignorable, depth=depth)

        subtree: Tree
        for subtree in self.branches:
            subtree.rtrim_ignored(depth=depth - 1)

        return self

    def rtrim_content_rule(self, fn: Callable[[PosixPath, int], bool], depth: int = math.inf) -> Self:
        """
        Apply business rule to contents.
        @param fn: Business function that determines whether the element will be removed or not, with depth provided.
        @param depth: Determines the maximum allowed depth to search.
        The default value is infinite.
        """
        if depth < 0:
            return self
        for pp in self.contents:
            if fn(pp, depth):
                # we do not want to descent to children branches while trimming, just this level
                self.rtrim_file(pp, depth=0)

        for branch in self.branches:
            branch.rtrim_content_rule(fn, depth=depth - 1)
        return self

    def rtrim_branch_rule(self, fn: Callable[[Self, int], bool], depth: int = math.inf) -> Self:
        """
        Apply business rule to branches.
        @param fn: Business function determines whether the element will be removed or not, with depth provided.
        @param depth: Determines the maximum allowed depth to search.
        The default value is infinite.
        """
        if depth < 0:
            return self
        for branch in self.branches:
            if fn(branch, depth):
                # we do not want to descent to children branches while trimming, just this level
                self.rtrim_branch(branch, depth=0)

        for branch in self.branches:
            branch.rtrim_branch_rule(fn, depth=depth - 1)
        return self

    @classmethod
    def resolve(cls, tld: PosixPath, stowignore: PosixPath) -> Iterable[Self | PosixPath]:
        """
        Resolve the structure of a .stowignore.
        @param tld: Top-level directory PosixPath
        @param stowignore: PosixPath pointing to a .stowignore.
        """

        # noinspection PyShadowingNames
        def handle_ignore_line(tld: PosixPath, sti_line: str) -> Iterator[str]:
            # the fact that we're forced to use os.path.join, and not PosixPath(tld / p)
            #  is evil, and speaks to the fact that the development of these two modules (iglob & Path)
            #  was completely disjointed
            return iglob(os.path.join(tld / sti_line), include_hidden=True)

        with open(stowignore, "r", encoding="UTF-8") as sti:
            for line in sti:
                trimmed_line = line.strip()
                for p in handle_ignore_line(tld, trimmed_line):
                    pp = PosixPath(p)
                    # return tree if it's a dir
                    if pp.is_dir():
                        yield Tree(pp)
                        continue
                    # return a posixpath for regular files
                    yield pp

        return

    @classmethod
    def move(cls, tree: Self, destination: PosixPath, fn: Callable[[PosixPath], bool]) -> None:
        """
        Move a tree to destination.
        Inclusive, meaning the top-level directory name of Tree will be considered the same as destination,
        e.g., it will not make a new folder of the same name.
        @param tree: Tree & contents we'll be moving.
        @param destination: Top-level directory we'll be copying everything to.
        @param fn: Business rule the destination PosixPath will have to fulfill.
        Should return true for items we *want* to create.
        """
        raise NotImplementedError  # TODO


@final
class PosixPathUtils:
    def __init__(self):
        raise RuntimeError("Cannot instantiate static class!")

    @staticmethod
    def convert_path_str_to_posixpath(p: str, strict=True) -> PosixPath:
        return PosixPath(os.path.expandvars(os.path.expanduser(p))).resolve(strict=strict)

    @staticmethod
    def posixpath_equals(el1: PosixPath, el2: PosixPath) -> bool:
        # if their "type" (file or dir) is different rather than the same, definitely doesn't equal
        #  .is_file() is used for convenience, it could be is_dir() for both instead
        if not (el1.is_file() == el2.is_file()):
            return False

        # if not on the same depth, doesn't equal
        if len(el1.parts) != len(el2.parts):
            return False

        # reverse components, since the tail is the one most likely to be different
        for el1_components, el2_components in zip(el1.parts[::-1], el2.parts[::-1]):
            if el1_components != el2_components:
                return False

        return True

    @staticmethod
    def get_fs_parts_len(thing: Tree | PosixPath) -> tuple[tuple[str, ...], int]:
        """
        @return: return the true path towards a thing, removing filenames, and counting fs structure
        """
        if isinstance(thing, PosixPath):
            parts = thing.absolute().parts if thing.is_dir() else thing.absolute().parts[:-1]
            return parts, len(parts)

        # "thing" is a tree here by necessity due to prior explicit check
        thing: Tree
        return thing.absolute.parts, len(thing.absolute.parts)


@final
class Stower:
    # noinspection PyShadowingNames
    def __init__(self,
                 source: PosixPath,
                 destination: PosixPath,
                 skippables: list[PosixPath] = None,
                 force=False,
                 overwrite_others=False,
                 make_parents=False):
        self.src = source
        self.dest = destination
        self.skippables = skippables

        # empty flags
        self.force = force
        self.overwrite_others = overwrite_others
        self.make_parents = make_parents

        # aka working tree directory, reflects the current filesystem structure
        self.src_tree: Tree = Tree(self.src)

    def _prompt(self) -> bool:
        """
        Prompt the user for an input, [Y/n].
        @return:
        """
        while True:
            try:
                reply = input("Are you sure you want to continue [Y/n]? ").lower()
            except KeyboardInterrupt:
                return False
            except EOFError:
                # this catch doesn't work through the IDE, but in regular runs it works
                #  leave it as-is
                return False

            if reply != "y" and reply != "n":
                print(f"Invalid reply {reply}, please answer with Y/y for Yes, or N/n for no.")
                continue
            return reply == "y"

    def stow(self):
        """
        @raise PathError: if src and dest are the same
        """
        if PosixPathUtils.posixpath_equals(self.src, self.dest):
            raise PathError("Source cannot be the same as destination!")

        # effective user id name, to be compared to .owner()
        euidn = getpass.getuser()

        # first step: create the tree of the entire src folder
        self.src_tree.traverse()
        # second step: apply preliminary business rule to the tree:
        #  trim explicitly excluded items
        # the reason we're doing the explicitly excluded items first, is simple
        #  the fact is that explicitly --exclude item(s) will most likely be less than the ones in .stowignore
        #  so, we're probably saving time since we don't have to trim .stowignored files that do not apply
        for content in filter(lambda sk: sk.is_file(), self.skippables):
            self.src_tree.rtrim_file(content)
        for branch in filter(lambda sk: sk.is_dir(), self.skippables):
            self.src_tree.rtrim_branch(Tree(branch))
        # third step: trim the tree from top to bottom, for every .stowignore we find, we will apply
        #  the .stowignore rules only to the same-level trees and/or files, hence, provably and efficiently
        #  trimming all useless paths
        self.src_tree.rtrim_ignored()
        if not self.overwrite_others:
            # fourth step (optional): apply extra business rules to the tree:
            #  ignore items owned by other users
            # if the euid (effective user id) name is different from the folder's owner name, trim it
            self.src_tree.rtrim_content_rule(
                lambda pp, _: pp.owner() != euidn
            )
            self.src_tree.rtrim_branch_rule(
                lambda br, _: br.absolute.owner() != euidn
            )

        # fifth step: move the populated tree
        print("The following action is not reversible.")
        print(f"Linking the following tree to destination {self.dest} . . .")
        print(self.src_tree)
        approved = self._prompt()
        if not approved:
            print("Aborting.")

        # Someone would say this is an ugly implementation due to the many lambda functions.
        # However, I'd say it's a pretty cool implementation,
        # since all of these rules are explicit business rules,
        # and could be substituted for whatever in the future
        if approved:
            print("Linking!")
            # no overwriting existing links rule
            exists_rule = lambda dpp: not dpp.exists(follow_symlinks=False)
            if self.force:
                exists_rule = lambda dpp: True
            # no overwriting other people's links rule
            others_rule = lambda dpp: dpp.owner() == euidn
            if self.overwrite_others:
                others_rule = lambda dpp: True
            # no overwriting files, only symlinks rule
            symlinks_rule = lambda dpp: dpp.is_symlink()
            # no overwriting original tree rule
            #  here, we're comparing the absolute posixpath of the original tree,
            #  with the target (destination) posixpath
            #  if they're the same, we do NOT want to overwrite the tree
            keep_original_rule = lambda dpp: dpp not in self.src_tree
            # If we'd overwrite the src tree by copying a specific link to dest, abort due to fatal conflict.
            #  For example, consider the following src structure:
            #  dotfiles
            #    > dotfiles
            #  gets stowed to destination /.../dotfiles/.
            #  the inner dotfiles/dotfiles symlink to dotfiles/.
            #  would overwrite the original tree, resulting in a catastrophic failure where everything is borked.
            Tree.move(
                self.src_tree,
                self.dest,
                fn=lambda dpp: exists_rule(dpp) and
                               others_rule(dpp) and
                               symlinks_rule(dpp) and
                               keep_original_rule(dpp)
            )


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
        "--loose", "-l",
        required=False,
        action="store_false",
        default=True,
        help="Loose restrictions on source & destination file paths. Will allow symlinks to be resolved."
    )
    ap.add_argument(
        "--force", "-f",
        required=False,
        action="store_true",
        default=False,
        help="Force overwrite of any conflicting soft links. This will not overwrite regular files."
    )
    ap.add_argument(
        "--overwrite-others", "-o",
        required=False,
        action="store_true",
        default=False,
        help="Ovewrite links/files owned by other users than the current one."
             "Default behaviour is to not overwrite files not owned by the current user/"
             "Functionally the same as --no-preserve-root in the rm command."
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
        oo = args.overwrite_others
        mp = args.make_parents

        Stower(
            src, dest,
            skippables=excluded,
            force=force,
            overwrite_others=oo,
            make_parents=mp,
        ).stow()
    except FileNotFoundError as e:
        print(f"Couldn't find file!\n{e}")
    except PathError as e:
        print(f"Invalid operation PathError!\n{e}")
