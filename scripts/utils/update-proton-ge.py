#!/usr/bin/env python3
import os
import sys
import time
import argparse as ap
import update_utils as utils


def match_correct_release(link, title=None):
    releases = utils.get_github_releases(link, recurse=False if not title else True)
    if not releases:
        print(f"Unknown error, couldn't get all github releases for {link}")
        exit(1)

    print(f"Found {len(releases)} valid releases.")
    if not title:
        return releases[0]

    for release in releases:
        if title in release.tag_name.lower():
            return release

    return None


if utils.is_root():
    print("Do NOT run this script as root.", file=sys.stderr)
    exit(2)

DOWNLOAD_DIR = "/tmp/"
PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
INSTALL_DIR = os.path.expanduser("~/.local/share/Steam/compatibilitytools.d/")
VERSION = None

parser = ap.ArgumentParser(
    description="Download & extract latest version of GE-Proton\n\thttps://github.com/GloriousEggroll/proton-ge-custom"
)
parser.add_argument("-d", "--destination", help="specify installation directory", required=False)
parser.add_argument("-t", "--temporary", help="specify temporary download directory", required=False)
parser.add_argument(
    "-k", "--keep",
    help="keep downloaded files in download directory",
    required=False,
    action="store_true"
)
parser.add_argument("-l", "--logo", help="do not print the utility logo", required=False, action="store_true")
parser.add_argument(
    "-v",
    "--version",
    help="specific version to install, with standard GE-Proton naming format e.g. 7-46",
    required=False,
    default=None
)
subparser = parser.add_subparsers(dest="subcommand", required=False)
ls_parser = subparser.add_parser("ls", help="print the currently installed versions, separated by newline")
versions_parser = subparser.add_parser("versions", help="print all the GE-Proton released versions to date")
args = parser.parse_args()

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
            for v in utils.get_github_releases(PROTON_GE_GITHUB_RELEASES_URL, recurse=True):
                print(v.tag_name)
            exit(0)
        case _:
            print("Unknown subcommand, exiting...")
            exit(2)

if not args.logo:
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

if not os.path.exists(INSTALL_DIR):
    os.makedirs(INSTALL_DIR)

release = match_correct_release(PROTON_GE_GITHUB_RELEASES_URL, title=VERSION)
if not release:
    print(f"Couldn't match any release for version {VERSION}")
    exit(1)
print(f"Found correct version {release.tag_name}")
ftarballname = None
ftarballurl = None
fhashname = None
fhashurl = None
for n, l in release.assets.items():
    if "tar.gz" in n:
        ftarballname = DOWNLOAD_DIR + os.sep + n
        ftarballurl = l
    if "sha512sum" in n:
        fhashname = DOWNLOAD_DIR + os.sep + n
        fhashurl = l

if not fhashname or not ftarballname:
    print(f"Couldn't find a sha512sum or tarball for version {release.tag_name}")
    exit(1)

# download sha512sum
try:
    with open(fhashname, "wb") as out:
        print(f"Writing {fhashname} from url {fhashurl}")
        for bread, btotal, data in utils.download(fhashurl):
            out.write(data)
            utils.echo_progress_bar_complex(bread, btotal, sys.stdout, os.get_terminal_size().columns)
    print(f"\nDownloaded {fhashname}")
except Exception as e:
    print(e, out=sys.stderr)
    exit(1)

# download tarball
try:
    with open(ftarballname, "wb") as out:
        print(f"Writing {ftarballname} from url {ftarballurl}")
        for bread, btotal, data in utils.download(ftarballurl):
            out.write(data)
            utils.echo_progress_bar_complex(bread, btotal, sys.stdout, os.get_terminal_size().columns)
    print(f"\nDownloaded {ftarballname}")
except Exception as e:
    print(e, out=sys.stderr)
    exit(1)

if not utils.run_subprocess(["sha512sum", "-c", fhashname], DOWNLOAD_DIR):
    if not args.keep:
        os.remove(fhashname)
        os.remove(ftarballname)
    exit(1)

time.sleep(1)

if not utils.run_subprocess(["tar", "-xPf", ftarballname, f"--directory={INSTALL_DIR}"], DOWNLOAD_DIR):
    if not args.keep:
        os.remove(fhashname)
        os.remove(ftarballname)
    exit(1)
print(f"Extracted {ftarballname}")

# The default python module has a significant security vulnerability:
#  see more: https://docs.python.org/3/library/tarfile.html
# with tarfile.open(ftarballname, "r:gz") as tar:
#    tar.extractall()
#    tar.close()
#  to counter this, we used the shell utility instead

if not args.keep:
    os.remove(ftarballname)
    os.remove(fhashname)
    print(f"Removed {DOWNLOAD_DIR} files {ftarballname} & {fhashname}")

print(f"New contents are at {INSTALL_DIR}")
print("Done.")
