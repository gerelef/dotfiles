#!/usr/bin/env python3
from pathlib import Path
import requests
import urllib.request
import json
import sys
import os
import subprocess as sp
import argparse as ap


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


def echo_installed():
    dirs = os.listdir(path=INSTALL_DIR)
    for d in dirs:
        print(d)


def echo_versions(link):
    while True:
        with requests.get(link, verify=True) as req:
            if req.status_code != 200:
                print(f"Got status code {req.status_code}", file=sys.stderr)
                exit(1)
            releases_recvd = req.json()
            releases_links = req.links
        
        for index, version_map in enumerate(releases_recvd):
            print(version_map["tag_name"])
        try:
            link = releases_links['next']['url']
        except KeyError:
            break

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
            echo_installed()
            exit(0)
        case "versions":
            echo_versions(PROTON_GE_GITHUB_RELEASES_URL)
            exit(0)
        case _:
            print("Unknown subcommand, exiting...")
            exit(1)

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

rlc = 1
while True:
    print(f"Requesting first {rlc*30} results...")
    with requests.get(PROTON_GE_GITHUB_RELEASES_URL, verify=True) as req:
        if req.status_code != 200:
            print(f"Got status code {req.status_code}", file=sys.stderr)
            exit(1)
        releases_recvd = req.json()
        releases_links = req.links
    SHA512SUM_ASSET_INDEX = 0
    TAR_ASSET_INDEX = 1
    if not VERSION:
        INDEX_MATCHING_VERSION_NUMBER = 0
        break
    else:
        INDEX_MATCHING_VERSION_NUMBER = None
        for index, version_map in enumerate(releases_recvd):
            if VERSION in version_map["tag_name"]:
                INDEX_MATCHING_VERSION_NUMBER = index
                break
        
        if INDEX_MATCHING_VERSION_NUMBER:
            break
            
        rlc += 1
        try:
            PROTON_GE_GITHUB_RELEASES_URL = releases_links['next']['url']
        except KeyError:
            print("Ran out of results. Exiting...")
            exit(1)
print("Found correct version. Please note versions BELOW  Proton-6.5-GE-2 are NOT supported.")
# https://stackoverflow.com/questions/24346872/python-equivalent-of-a-given-wget-command
fname = DOWNLOAD_DIR + "/" + releases_recvd[INDEX_MATCHING_VERSION_NUMBER]["assets"][TAR_ASSET_INDEX]["name"]
tarball_url = releases_recvd[INDEX_MATCHING_VERSION_NUMBER]["assets"][TAR_ASSET_INDEX]["browser_download_url"]
download(fname, tarball_url)

fhashname = DOWNLOAD_DIR + "/" + releases_recvd[INDEX_MATCHING_VERSION_NUMBER]["assets"][SHA512SUM_ASSET_INDEX]["name"]
sha512sum_url = releases_recvd[INDEX_MATCHING_VERSION_NUMBER]["assets"][SHA512SUM_ASSET_INDEX]["browser_download_url"]
download(fhashname, sha512sum_url)

print("Done.")

sys.stdout.write("sha512sum status: ")
sys.stdout.flush()
run_subprocess(DOWNLOAD_DIR, ["sha512sum", "-c", fhashname], [fhashname, fname])

# The default python module has a significant security vulnerability:
#  see more: https://docs.python.org/3/library/tarfile.html
#with tarfile.open(fname, "r:gz") as tar:
#    tar.extractall()
#    tar.close()
#  to counter this, we're going to use the shell utility instead

print(f"Extracting {fname} ...")
run_subprocess(DOWNLOAD_DIR, ["tar", "-xPf", fname, f"--directory={INSTALL_DIR}"], [fhashname, fname])

if not args.keep:
    os.remove(fname)
    os.remove(fhashname)
    print(f"Removed {DOWNLOAD_DIR} files {fname} & {fhashname}")
    
print(f"New contents are at {INSTALL_DIR}")
print("Done.")
