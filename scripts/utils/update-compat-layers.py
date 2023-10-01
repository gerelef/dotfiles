#!/usr/bin/env python3
import os
import sys
import time
import argparse as ap
import update_utils as utils


def create_argparser() -> ap.ArgumentParser:
    p = ap.ArgumentParser(
        description="Download & extract latest version of the most popular compatibility layers"
    )
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--luxtorpeda",
        help="Download & extract latest version of Luxtorpeda\n\thttps://github.com/luxtorpeda-dev/luxtorpeda",
        required=False,
        action="store_true"
    )
    group.add_argument(
        "--league",
        help="Download & extract latest version of Lutris-GE-X.x.x-LoL\n\thttps://github.com/gloriouseggroll/wine-ge-custom",
        required=False,
        action="store_true"
    )
    group.add_argument(
        "--wine",
        help="Download & extract latest version of Wine-GE-ProtonX-x\n\thttps://github.com/gloriouseggroll/wine-ge-custom",
        required=False,
        action="store_true"
    )
    group.add_argument(
        "--golden-egg",
        help="Download & extract latest version of GE-ProtonX-x\n\thttps://github.com/GloriousEggroll/proton-ge-custom",
        required=False,
        action="store_true"
    )
    p.add_argument(
        "-u", "--unsafe",
        help="skip checksum verification, even if supported",
        required=False,
        action="store_true"
    )
    p.add_argument(
        "-d", "--destination",
        help="specify installation directory",
        required=False
    )
    p.add_argument(
        "-t", "--temporary",
        help="specify temporary download directory",
        required=False
    )
    p.add_argument(
        "-k", "--keep",
        help="keep downloaded files in download directory",
        required=False,
        action="store_true"
    )
    p.add_argument(
        "-v", "--version",
        help="specific version to install, with standard GE-Proton naming format e.g. 7-46",
        required=False,
        default=None
    )
    subparser = p.add_subparsers(dest="subcommand", required=False)
    ls_parser = subparser.add_parser("ls", help="print the currently installed versions, separated by newline")
    versions_parser = subparser.add_parser("versions", help="print all the GE-Proton released versions to date")
    return p


def setup_argument_options(argparser_output) -> None:
    global DOWNLOAD_DIR, COMPATIBILITY_LAYER_URL, INSTALL_DIR, VERSION, RELEASE_FILTER

    # FIXME missing golden-egg check since it was removed from being the default and became a flag
    if args.luxtorpeda:
        args.unsafe = True  # as of writing, luxtorpeda doesn't have a sha512sum in their assets.
        COMPATIBILITY_LAYER_URL = LUXTORPEDA_GITHUB_RELEASES_URL

    if args.league or args.wine:
        RELEASE_FILTER = lambda s: "proton" in s
        if args.league:
            RELEASE_FILTER = lambda s: "lol" in s
        INSTALL_DIR = os.path.expanduser("~/.local/share/lutris/runners/wine/")
        COMPATIBILITY_LAYER_URL = WINE_GE_GITHUB_RELEASES_URL

    if args.destination:
        INSTALL_DIR = os.path.abspath(os.path.expanduser(args.destination))

    if args.temporary:
        DOWNLOAD_DIR = os.path.abspath(os.path.expanduser(args.temporary))
        if not os.path.exists(DOWNLOAD_DIR):
            os.makedirs(DOWNLOAD_DIR)

    if args.version:
        VERSION = args.version

    if args.subcommand:
        match args.subcommand:
            case "ls":
                dirs = utils.get_all_subdirectories(INSTALL_DIR)
                for d in dirs:
                    print(d)
                exit(0)
            case "versions":
                for v in utils.get_github_releases(COMPATIBILITY_LAYER_URL, recurse=True):
                    if RELEASE_FILTER and not RELEASE_FILTER(v.tag_name.lower()):
                        continue
                    print(v.tag_name)
                exit(0)
            case _:
                print("Unknown subcommand, exiting...")
                exit(2)


if utils.is_root():
    print("Do NOT run this script as root.", file=sys.stderr)
    exit(2)

DOWNLOAD_DIR = "/tmp/"
PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
WINE_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/gloriouseggroll/wine-ge-custom/releases"
LUXTORPEDA_GITHUB_RELEASES_URL = "https://api.github.com/repos/luxtorpeda-dev/luxtorpeda/releases"
COMPATIBILITY_LAYER_URL = PROTON_GE_GITHUB_RELEASES_URL  # default compat layer to install
INSTALL_DIR = os.path.expanduser("~/.local/share/Steam/compatibilitytools.d/")
VERSION = None
RELEASE_FILTER = None

if __name__ == "__main__":
    parser = create_argparser()
    args = parser.parse_args()
    setup_argument_options(args)

    if not os.path.exists(INSTALL_DIR):
        os.makedirs(INSTALL_DIR)

    release = utils.match_correct_release(COMPATIBILITY_LAYER_URL, title=VERSION, _filter=RELEASE_FILTER)
    if not release:
        print(f"Couldn't match any release for version {VERSION}")
        exit(1)
    print(f"Found correct version{' Luxtorpeda' if args.luxtorpeda else ''} {release.tag_name}")

    print("""
    \033[5m
     _____  _____                   _              
    |  __ \|  ___|                 | |             
    | |  \/| |__    _ __  _ __ ___ | |_ ___  _ __  
    | | __ |  __|  | '_ \| '__/ _ \| __/ _ \| '_ \ 
    | |_\ \| |___  | |_) | | | (_) | || (_) | | | |
     \____/\____/  | .__/|_|  \___/ \__\___/|_| |_|
             ______| |______ ______ ______ ______  
        _   |______|_|______|______|______|______| 
       (_)         | |      | | |                  
        _ _ __  ___| |_ __ _| | | ___ _ __         
       | | '_ \/ __| __/ _` | | |/ _ \ '__|        
       | | | | \__ \ || (_| | | |  __/ |           
       |_|_| |_|___/\__\__,_|_|_|\___|_|           
    \033[0m
    """)

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

        if not utils.run_subprocess(["tar", "-xPf", ftarballname, f"--directory={INSTALL_DIR}"], DOWNLOAD_DIR):
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
    print(f"New contents are at {INSTALL_DIR}")
    print("Done.")
