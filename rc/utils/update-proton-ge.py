#!/usr/bin/env python3
from dataclasses import dataclass
from datetime import datetime
import requests
import urllib.request
import json
import sys
import os
import subprocess as sp
import argparse as ap


@dataclass
class GoldenEggRelease:
    date: str
    release_name: str
    tag_name: str
    body: str
    sha512_name: str
    sha512_url: str
    tarball_name: str
    tarball_url: str


def download(filename, url):
    print(f"Downloading {filename} from {url}...")
    with requests.get(url, verify=True, stream=True, allow_redirects=True) as req:
        btotal = int(req.headers.get('content-length'))
        bread = 0
        print(f"Size: {round((btotal/1024)/1024, 3)} MiB")
        with open(filename, 'wb') as out:
            print(f"Writing {filename} from url {url}")
            for data in req.iter_content(chunk_size=4096):
                bread += len(data)
                out.write(data)
                sys.stdout.write(f"\r{round((bread/btotal)*100, 2)}%")
                sys.stdout.flush()
    print()


def run_subprocess(cwd, commands, files): 
    if (ret := sp.run(commands, cwd=cwd).returncode) != 0:
        print(f"{' '.join(command)} exited with status != 0, aborting...")
        for f in files:
            os.remove(f)
        exit(ret)


def echo_installed(path):
    dirs = os.listdir(path=path)
    for d in dirs:
        print(d)


def echo_versions(link, verbose=False):
    releases = download_supported_ge_releases(link)
    print(f"Found {len(releases)} valid releases.")
    for release in releases:
        print(f"{release.date} {release.release_name if release.release_name else 'Unknown Release Name'}")
        if verbose:
            print(f"\f{release.body}")
            print("---")


def download_supported_ge_releases(link):
    releases: list[GoldenEggRelease] = []
    while True:
        with requests.get(link, verify=True) as req:
            if req.status_code != 200:
                print(f"Got status code {req.status_code}", file=sys.stderr)
                exit(1)
            releases_recvd = req.json()
            releases_links = req.links
        
        for version in releases_recvd:
            try:
                releases.append(
                    GoldenEggRelease(
                        # https://stackoverflow.com/a/36236080/10007109
                        datetime.strptime(version["published_at"], "%Y-%m-%dT%H:%M:%SZ"),
                        version["name"].strip(),
                        version["tag_name"],
                        version["body"],
                        version["assets"][0]["name"],
                        version["assets"][0]["browser_download_url"],
                        version["assets"][1]["name"],
                        version["assets"][1]["browser_download_url"]
                    )
                )
            except IndexError:
                # skip unsupported releases (those that do not have a hash and tarball)
                pass
        
        try:
            link = releases_links['next']['url']
        except KeyError:
            # if either next links don't exist, or the release format is not supported, stop here 
            break
    
    return releases


def match_correct_release(link, title_match=None):
    releases = download_supported_ge_releases(link)
    print(f"Found {len(releases)} valid releases.")
    if not title_match:
        return releases[0]
        
    for release in releases:
        if title_match in release.tag_name.lower():
            return release
    
    return None


if os.geteuid() == 0:
    print("Do NOT run this script as root.", file=sys.stderr)
    exit(2)

DOWNLOAD_DIR = "/tmp/"
PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
INSTALL_DIR = os.path.expanduser("~/.local/share/Steam/compatibilitytools.d/")
VERSION = None

parser = ap.ArgumentParser(description='Download & extract latest version of GE-Proton\n\thttps://github.com/GloriousEggroll/proton-ge-custom')
parser.add_argument('-d','--destination', help="specify installation directory", required=False)
parser.add_argument('-t','--temporary', help="specify temporary download directory", required=False)
parser.add_argument('-k','--keep', help="keep downloaded files in download directory", required=False, action="store_true")
parser.add_argument("version", help="specific version to install, with standard GE-Proton naming format e.g. 7-46", nargs='?', type=str, default=None) # positional version argument
subparser = parser.add_subparsers(dest="subcommands")
ls_parser = subparser.add_parser("ls", help="print the currently installed versions, separated by newline")
versions_parser = subparser.add_parser("versions", help="print all the GE-Proton released versions to date")
args = parser.parse_args()

if args.destination:
    INSTALL_DIR = os.path.abspath(os.path.expanduser(args.destination))
    if not os.path.exists(INSTALL_DIR):
        os.makedirs(INSTALL_DIR)

if args.temporary:
    DOWNLOAD_DIR = os.path.abspath(os.path.expanduser(args.temporary))
    if not os.path.exists(DOWNLOAD_DIR):
        os.makedirs(DOWNLOAD_DIR)

if args.version:
    VERSION = args.version

if args.subcommands:
    match args.subcommands:
        case "ls":
            echo_installed(INSTALL_DIR)
            exit(0)
        case "versions":
            echo_versions(PROTON_GE_GITHUB_RELEASES_URL)
            exit(0)
        case _:
            print("Unknown subcommand, exiting...")
            exit(2)

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

release = match_correct_release(version=VERSION)
if not release:
    print(f"Couldn't match any release for version {VERSION}")
    exit(1)
print(f"Found correct version {release.tag_name}")

fhashname = DOWNLOAD_DIR + "/" + release.sha512_name
download(fhashname, release.sha512_url)
print(f"Downloaded {release.sha512_name}")

ftarballname = DOWNLOAD_DIR + "/" + release.tarball_name
download(ftarballname, release.tarball_url)
print(f"Downloaded {release.tarball_name}")

sys.stdout.write("sha512sum status: ")
run_subprocess(DOWNLOAD_DIR, ["sha512sum", "-c", fhashname], [fhashname, ftarballname])

print(f"Extracting {ftarballname} ...")
run_subprocess(DOWNLOAD_DIR, ["tar", "-xPf", ftarballname, f"--directory={INSTALL_DIR}"], [fhashname, ftarballname])

# The default python module has a significant security vulnerability:
#  see more: https://docs.python.org/3/library/tarfile.html
#with tarfile.open(ftarballname, "r:gz") as tar:
#    tar.extractall()
#    tar.close()
#  to counter this, we used the shell utility instead

if not args.keep:
    os.remove(ftarballname)
    os.remove(fhashname)
    print(f"Removed {DOWNLOAD_DIR} files {ftarballname} & {fhashname}")
    
print(f"New contents are at {INSTALL_DIR}")
print("Done.")
