#!/usr/bin/env -S python3.12 -S -OO
# From the documentation:
# >"If the readline module was loaded,
#  then input() will use it to provide elaborate line editing and history features."
# noinspection PyUnresolvedReferences
import readline
import getpass
import math
import os
import shutil
import logging
from argparse import ArgumentParser
from glob import iglob
from itertools import zip_longest
from pathlib import PosixPath
from typing import Iterable, final, Self, Optional, Callable, Iterator


class PathError(RuntimeError):
    pass


# class & logger setup ripped straight out of here
# https://stackoverflow.com/a/56944256
class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    format = "%(levelname)s: %(message)s"

    FORMATS = {
        logging.INFO: "%(message)s " + reset,  # use this for user-facing output
        logging.DEBUG: reset + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


# AUTHOR'S NOTE:
# For future refence, a nice refactor would be to move the tree ops outside the class because it's bloated
#  but currently, I do not want to deal with multiple files for this particular project.
#  However, an ops @property would be the cool way to do it, with a TreeOperator(self) "bridge".
# Recursive-trim functions do not affect the filesystem, they just remove them from the tree.
@final
class Tree:
    REAL_USER_HOME = f"{str(PosixPath().home())}"

    def __init__(self, tld: PosixPath):
        self.__tld: PosixPath = tld.absolute()
        self.__tree: list[Self | PosixPath] = []
        self.__stowignore: Optional[Stowconfig] = None

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

    def __contains__(self, other: Self | PosixPath) -> bool:
        """
        Non-recursive check if we contain an element.
        @param other:
        @return:
        """
        if other is None:
            return False
        self_parts, self_parts_len = PosixPathUtils.get_fs_parts_len(self.absolute)
        if isinstance(other, Tree):
            other_parts, other_parts_len = PosixPathUtils.get_fs_parts_len(other.absolute)
        else:
            other_parts, other_parts_len = PosixPathUtils.get_fs_parts_len(other.absolute())

        # if the other parts are less than ours, meaning
        #  my/path/1
        #  my/path
        # it means that my/path is definitely not contained within our tree
        if other_parts_len < self_parts_len:
            return False

        # zip_longest, not in reverse, since the other_parts might be in a subdirectory,
        #  we just want to check if the tld equivalent is us
        for spc, opc in zip(self_parts, other_parts):
            if spc != opc:
                return False

        return True

    def __repr__(self) -> str:
        return str(self.absolute)

    def repr(self, indentation: int = 0):
        """
        @param indentation: indentation level.
        @return: Tree representation of the current tree.
        """

        def shorten_home(p: Tree | PosixPath) -> str:
            ps = p.name if isinstance(p, PosixPath) else repr(p)
            if ps.startswith(Tree.REAL_USER_HOME):
                return ps.replace(Tree.REAL_USER_HOME, "~", 1)
            return ps

        out: list[str] = [f"\033[96m{"─" * indentation}─> \033[1m{shorten_home(self)}\033[0m"]
        for content in self.contents:
            out.append(f"\033[96m\033[93m{"─" * (indentation + 4)}─> \033[3m{shorten_home(content)}\033[0m")
        for branch in self.branches:
            out.append(branch.repr(indentation=indentation + 4))
        return "\n\033[96m\033[0m".join(out)

    @property
    def stowignore(self):
        return self.__stowignore

    @property
    def absolute(self) -> PosixPath:
        """
        @return: Top-level directory, a PosixPath.
        """
        return self.__tld

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
            if fn == Stowconfig.STOWIGNORE_FN:
                self.__stowignore = Stowconfig(pp)

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
            if rcont.name == Stowconfig.STOWIGNORE_FN:
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

        for branch in self.branches:
            branch.rtrim_branch(removable_branch, depth=depth - 1)

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
            for ignorable in self.stowignore.parse():
                if isinstance(ignorable, Tree):
                    self.rtrim_branch(ignorable, depth=depth)
                    continue

                self.rtrim_file(ignorable, depth=depth)

        subtree: Tree
        for subtree in self.branches:
            subtree.rtrim_ignored(depth=depth - 1)

        return self

    # noinspection PyShadowingNames
    @classmethod
    def rsymlink(cls, tree: Self, destination: PosixPath, fn: Callable[[PosixPath], bool], make_parents=True) -> None:
        """
        Recursively symlink a tree to destination.
        Inclusive, meaning the top-level directory name of Tree will be considered the same as destination,
        e.g., it will not make a new folder of the same name for the tld. However, it'll create a 1:1 copy
        for subtrees.
        If the directory doesn't exist, it'll be created.
        @param tree: Tree, whose contents we'll be moving.
        @param destination: Top-level directory we'll be copying everything to.
        @param fn: Business rule the destination PosixPath will have to fulfill.
        Should return true for items we *want* to create.
        Sole argument is the destination (target) PosixPath.
        @param make_parents: equivalent --make-parents in mkdir -p
        """
        if not destination.exists(follow_symlinks=False) and not make_parents:
            raise PathError(f"Expected valid target, but got {destination}, which doesn't exist?!")
        if destination.exists(follow_symlinks=False) and not destination.is_dir():
            raise PathError(f"Expected valid target, but got {destination}, which isn't a directory?!")

        if not destination.exists(follow_symlinks=False) and make_parents:
            logger.info(f"\033[96mCreating destination which doesn't exist {destination}\033[0m")
            shutil.copytree(
                src=tree.absolute,
                dst=destination.absolute(),
                symlinks=False,
                ignore=lambda src, names: ['.'] + [name for name in names if os.path.isfile(os.path.join(src, name))],
                dirs_exist_ok=False
            )

        content: PosixPath
        for content in tree.contents:
            destination_content = PosixPath(destination / content.name)
            if not fn(destination_content):
                logger.info(f"\033[91mSkipping {destination_content} due to policy\033[0m")
                continue

            logger.info(f"Symlinking src {content} to {destination_content}")
            if destination_content.exists(follow_symlinks=False):
                if destination_content.is_symlink():
                    os.unlink(destination_content.absolute())
                else:
                    os.remove(destination_content.absolute())

            os.symlink(
                src=content.absolute(),
                dst=destination_content.absolute(),
                target_is_directory=False
            )

        branch: Tree
        for branch in tree.branches:
            destination_dir = PosixPath(destination / branch.name)
            branch.rsymlink(
                tree=branch,
                destination=destination_dir,
                fn=fn
            )


class Stowconfig:
    STOWIGNORE_FN = ".stowconfig"

    def __init__(self, fstowignore: PosixPath):
        """
        @param fstowignore: stowignore PosixPath
        """
        self.fstowignore = fstowignore
        self.parent = fstowignore.parent

    def _handle_ignore_line(self, stowignore_line: str) -> Iterator[str]:
        # the fact that we're forced to use os.path.join, and not PosixPath(tld / p)
        #  is evil, and speaks to the fact that the development of these two modules (iglob & Path)
        #  was completely disjointed
        return iglob(os.path.join(self.parent / stowignore_line), recursive=True, include_hidden=True)

    def _handle_redirect_lines(self, source: PosixPath, target: PosixPath):
        raise NotImplementedError

    def parse(self) -> Iterable[Tree | PosixPath]:
        """
        Resolve the structure of a STOWIGNORE_FN.
        """
        # noinspection PyShadowingNames
        with open(self.fstowignore, "r", encoding="UTF-8") as sti:
            for line in sti:
                trimmed_line = line.strip()
                for p in self._handle_ignore_line(trimmed_line):
                    pp = PosixPath(p)
                    # return tree if it's a dir
                    if pp.is_dir():
                        yield Tree(pp)
                        continue
                    # return a posixpath for regular files
                    yield pp
        return


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
        # zip_longest is used since if, for any reason, the path is not the same, on any level,
        # they're not equal
        for el1_components, el2_components in zip_longest(el1.parts[::-1], el2.parts[::-1]):
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
                logger.info(f"Invalid reply {reply}, please answer with Y/y for Yes, or N/n for no.")
                continue
            return reply == "y"

    def stow(self, readonly: bool = False):
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
        for content in filter(lambda sk: sk.is_file() and sk in self.src_tree, self.skippables):
            self.src_tree.rtrim_file(content)
        for branch in filter(lambda sk: sk.is_dir() and sk in self.src_tree, self.skippables):
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

        # fifth step: symlink the populated tree
        logger.info("The following action is not reversible.")
        logger.info(f"Linking the following tree to destination {self.dest} . . .")
        logger.info(f"{self.src_tree.repr()}")
        approved = self._prompt() if not readonly else False
        if not approved:
            logger.warning("Aborting.")

        # Someone could say this is an ugly implementation due to the many lambda functions.
        # However, I'd say it's a pretty cool implementation,
        # since all of these rules are explicit business rules,
        # and could be substituted for whatever in the future
        if approved:
            logger.info("Linking...")
            # overwrite nothing that already exists rule
            exists_rule = lambda dpp: not dpp.exists(follow_symlinks=False)
            if self.force:
                # overwrite only symlinks rule
                exists_rule = lambda dpp: dpp.is_symlink() if dpp.exists(follow_symlinks=False) else True
            # overwite only our own links rule
            #  .exists() is here for sanity reasons, because it's not a given that
            #  the file does actually exist, and due to lazy eval, this will work even if it isn't there
            others_rule = lambda dpp: dpp.owner() == euidn if dpp.exists(follow_symlinks=False) else True
            if self.overwrite_others:
                others_rule = lambda dpp: True
            # overwrite if not in the original tree rule
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
            Tree.rsymlink(
                self.src_tree,
                self.dest,
                make_parents=self.make_parents,
                fn=lambda dpp: exists_rule(dpp) and
                               others_rule(dpp) and
                               keep_original_rule(dpp),
            )


def get_arparser() -> ArgumentParser:
    ap = ArgumentParser(
        "A spiritual reimplementation, perhaps simpler but more verbose, of GNU Stow."
    )
    ap.add_argument(
        "--source", "-s",
        type=str,
        required=False,
        default=os.getcwd(),
        help="Source directory links will be copied from."
    )
    ap.add_argument(
        "--target", "-t",
        type=str,
        required=True,
        help="Destination/target directory links will be soft-linked to."
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
        "--no-parents", "-p",
        required=False,
        action="store_true",
        default=False,
        help="Don't make parent directories as we traverse the tree in destination, even if they do not exist."
    )
    ap.add_subparsers(dest="command", required=False).add_parser(
        "status",
        help="Echo the current status of the stow src."
    )

    return ap


def get_logger() -> logging.Logger:
    # create logger
    # noinspection PyShadowingNames
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    # create console handler with a higher log level
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(CustomFormatter())

    logger.addHandler(ch)
    return logger


if __name__ == "__main__":
    logger = get_logger()
    args = get_arparser().parse_args()
    try:
        src = PosixPathUtils.convert_path_str_to_posixpath(args.source, strict=not args.loose)
        dest = PosixPathUtils.convert_path_str_to_posixpath(args.target, strict=not args.loose)
        excluded = [
            PosixPathUtils.convert_path_str_to_posixpath(str_path, strict=not args.loose) for str_path in args.exclude
        ]
        force = args.force
        oo = args.overwrite_others
        mp = not args.no_parents

        Stower(
            src, dest,
            skippables=excluded,
            force=force,
            overwrite_others=oo,
            make_parents=mp,
        ).stow(readonly=args.command == "status")
    except FileNotFoundError as e:
        logger.error(f"Couldn't find file!\n{e}")
    except PathError as e:
        logger.error(f"Invalid operation PathError!\n{e}")
