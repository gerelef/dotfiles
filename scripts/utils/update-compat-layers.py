#!/usr/bin/env python3
import os
import sys
import types

import requests
from typing import Any
from update_utils import Manager, Exceptions, get_default_argparser, euid_is_root, Filename, Release, URL


class CompatibilityManager(Manager):

    def __init__(self, repository: URL, install_dir: Filename, temp_dir: Filename, version=None, keyword: str = None):
        super().__init__(repository, download_dir=temp_dir)
        self.install_dir = install_dir
        self.keyword = keyword
        self.version = version

    def filter(self, release: Release) -> bool:
        lower_tag_name = release.tag_name.lower()

        version_matches = True
        if self.version:
            version_matches = self.version not in lower_tag_name

        keyword_matches = True
        if self.keyword:
            keyword_matches = self.keyword not in lower_tag_name
        return version_matches and keyword_matches

    # TODO create a specific function for each distinct repository required and assign to this
    def get_assets(self, r: Release) -> dict[Filename, URL]:
        pass

    def verify(self, files: list[Filename]) -> bool:
        pass

    def install(self, files: list[Filename]):
        pass

    def cleanup(self, files: list[Filename]):
        print("CLEANUP CALLED!!!1")
        # FIXME
        # for filename in files:
        #     real_path = os.path.join(self.download_dir, filename)
        #     if os.path.exists(real_path):
        #         os.remove(filename)

    def log(self, level: Manager.Level, msg: str):
        print(msg)


def create_argparser():
    p = get_default_argparser("Download & extract latest version of the most popular game compatibility layers.")
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--luxtorpeda",
        help="Download & extract latest version of Luxtorpeda\n"
             "\thttps://github.com/luxtorpeda-dev/luxtorpeda",
        required=False,
        default=False,
        action="store_true"
    )
    group.add_argument(
        "--league",
        help="Download & extract latest version of Lutris-GE-X.x.x-LoL\n"
             "\thttps://github.com/gloriouseggroll/wine-ge-custom",
        required=False,
        default=False,
        action="store_true"
    )
    group.add_argument(
        "--wine",
        help="Download & extract latest version of Wine-GE-ProtonX-x\n"
             "\thttps://github.com/gloriouseggroll/wine-ge-custom",
        required=False,
        default=False,
        action="store_true"
    )
    group.add_argument(
        "--golden-egg",
        help="Download & extract latest version of GE-ProtonX-x\n"
             "\thttps://github.com/GloriousEggroll/proton-ge-custom",
        required=False,
        default=False,
        action="store_true"
    )
    return p


PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
WINE_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/gloriouseggroll/wine-ge-custom/releases"
LUXTORPEDA_GITHUB_RELEASES_URL = "https://api.github.com/repos/luxtorpeda-dev/luxtorpeda/releases"
PROTON_GE_INSTALL_DIR = os.path.expanduser("~/.local/share/Steam/compatibilitytools.d/")
DOWNLOAD_DIR = "/tmp/"


def setup_argument_options(args: dict[str, Any]) -> CompatibilityManager:
    remote = None
    league_wine_filter = None
    version_filter = None
    temp_dir = DOWNLOAD_DIR
    install_dir = PROTON_GE_INSTALL_DIR
    # pick the first version by default
    # FIXME bind all of these mthods
    filter_method = CompatibilityManager.FILTER_FIRST
    verification_method = CompatibilityManager.verify
    cleanup_method = CompatibilityManager.cleanup

    for arg in args:
        match arg:
            case "golden_egg":
                if args[arg]:
                    remote = PROTON_GE_GITHUB_RELEASES_URL
            case "wine":
                if args[arg]:
                    remote = WINE_GE_GITHUB_RELEASES_URL
            case "league":
                if args[arg]:
                    remote = WINE_GE_GITHUB_RELEASES_URL
                    filter_method = CompatibilityManager.filter
                    league_wine_filter = "lol"
            case "luxtorpeda":
                if args[arg]:
                    remote = LUXTORPEDA_GITHUB_RELEASES_URL
                    verification_method = CompatibilityManager.DO_NOTHING
            case "unsafe":
                if args[arg]:
                    verification_method = CompatibilityManager.DO_NOTHING
            case "destination":
                if args[arg]:
                    install_dir = os.path.abspath(os.path.expanduser(args[arg]))
                    if not os.path.exists(install_dir):
                        os.makedirs(install_dir)
            case "temporary":
                if args[arg]:
                    temp_dir = os.path.abspath(os.path.expanduser(args[arg]))
                    if not os.path.exists(temp_dir):
                        os.makedirs(temp_dir)
            case "keep":
                if args[arg]:
                    cleanup_method = CompatibilityManager.DO_NOTHING
            case "version":
                if args[arg]:
                    filter_method = CompatibilityManager.filter
                    version_filter = args[arg]
            case _:
                raise RuntimeError(f"Unknown argument {arg}")
    manager = CompatibilityManager(
        repository=remote,
        install_dir=install_dir,
        temp_dir=temp_dir,
        version=version_filter,
        keyword=league_wine_filter,
    )
    # these new methods need to be bound to the instance of the class in order to use self
    manager.filter = types.MethodType(filter_method, manager)
    manager.verify = types.MethodType(verification_method, manager)
    manager.cleanup = types.MethodType(cleanup_method, manager)
    return manager


if euid_is_root():
    print("Do NOT run this script as root!", file=sys.stderr)
    exit(2)


if __name__ == "__main__":
    parser = create_argparser()
    compat_manager = setup_argument_options(vars(parser.parse_args()))
    print("""
        \033[5m
                                  _          
                                 | |         
   ___ ___  _ __ ___  _ __   __ _| |_        
  / __/ _ \\| '_ ` _ \\| '_ \\ / _` | __|       
 | (_| (_) | | | | | | |_) | (_| | |_        
  \\___\\___/|_| |_| |_| .__/ \\__,_|\\__|       
                     | |                     
  ______ ______ _____|_|_____ ______         
 |______|______|______|______|______|        
         (_)         | |      | | |          
          _ _ __  ___| |_ __ _| | | ___ _ __ 
         | | '_ \\/ __| __/ _` | | |/ _ | '__|
         | | | | \\__ | || (_| | | |  __| |   
         |_|_| |_|___/\\__\\__,_|_|_|\\___|_|   
\033[0m
        """)
    try:
        compat_manager.run()
    except KeyboardInterrupt:
        print("Aborted by user. Exiting...")
        exit(130)
    except Exceptions.NoReleaseFound as e:
        print("Couldn't find a matching release! Exiting...", file=sys.stderr)
        exit(1)
    except Exceptions.FileVerificationFailed as e:
        print("Couldn't verify the downloaded files! Exiting...", file=sys.stderr)
        exit(1)
    except RuntimeError as e:
        print(f"Got unknown exception {e}! Exiting...", file=sys.stderr)
        exit(1)
    except requests.ConnectionError as e:
        print(f"Got {e}! Is the network connection OK?", file=sys.stderr)
        exit(1)
    except requests.Timeout as e:
        # FIXME Duplicate code for no reason
        print(f"Got {e}! Is the network connection OK?", file=sys.stderr)
        exit(1)

    print("Done!")

    if not os.path.exists(PROTON_GE_INSTALL_DIR):
        os.makedirs(PROTON_GE_INSTALL_DIR)

    release = utils.match_correct_release(COMPATIBILITY_LAYER_URL, title=VERSION, _filter=RELEASE_FILTER)
    if not release:
        print(f"Couldn't match any release for version {VERSION}")
        exit(1)
    print(f"Found correct version{' Luxtorpeda' if args.luxtorpeda else ''} {release.tag_name}")

    ftarballname = None
    ftarballurl = None
    fhashname = None
    fhashurl = None
    for n, l in release.assets.items():
        if "tar" in n:
            ftarballname = DOWNLOAD_DIR + os.sep + n
            ftarballurl = l
        if "sha512sum" in n:
            fhashname = DOWNLOAD_DIR + os.sep + n
            fhashurl = l

    if not fhashname:
        print(f"Couldn't find a sha512sum for version {release.tag_name}")
        if not args.unsafe:
            exit(1)

    if not ftarballname:
        print(f"Couldn't find a tarball for version {release.tag_name}")
        exit(1)

    try:
        # download sha512sum
        if not args.unsafe:
            with open(fhashname, "wb") as out:
                print(f"Writing {fhashname} from url {fhashurl}")
                for bread, btotal, data in utils.download(fhashurl):
                    out.write(data)
                    utils.echo_progress_bar_complex(bread, btotal, sys.stdout, os.get_terminal_size().columns)
                print(f"\nDownloaded {fhashname}")

        # download tarball
        with open(ftarballname, "wb") as out:
            print(f"Writing {ftarballname} from url {ftarballurl}")
            for bread, btotal, data in utils.download(ftarballurl):
                out.write(data)
                utils.echo_progress_bar_complex(bread, btotal, sys.stdout, os.get_terminal_size().columns)
        print(f"\nDownloaded {ftarballname}")
    except KeyboardInterrupt:
        print("Interrupted by user.")
        exit(0)
    except Exception as e:
        print(f"Unknown exception {e}", out=sys.stderr)
        exit(1)

    try:
        # there's no sha512sum to download in luxtorpeda (as of writing)
        if not args.unsafe and not utils.run_subprocess(["sha512sum", "-c", fhashname], DOWNLOAD_DIR):
            exit(1)

        if not utils.run_subprocess(["tar", "-xPf", ftarballname, f"--directory={PROTON_GE_INSTALL_DIR}"],
                                    DOWNLOAD_DIR):
            exit(1)
        print(f"Extracted {ftarballname}")

        # The default python module has a significant security vulnerability:
        #  see more: https://docs.python.org/3/library/tarfile.html
        # with tarfile.open(ftarballname, "r:gz") as tar:
        #    tar.extractall()
        #    tar.close()
        #  to counter this, we used the shell utility instead
    except KeyboardInterrupt:
        print("Interrupted by user.")
        exit(0)
    finally:
        if not args.keep:
            if fhashname:
                os.remove(fhashname)
            if ftarballname:
                os.remove(ftarballname)
            print(f"Removed {DOWNLOAD_DIR} files.")
    print(f"New contents are at {PROTON_GE_INSTALL_DIR}")
    print("Done.")
