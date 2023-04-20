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
    print(f"Downloading {filename}...")
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


if os.geteuid() == 0:
    print("Do NOT run this script as root.", file=sys.stderr)
    sys.exit(2)
    
parser = ap.ArgumentParser(description='Download & extract latest version of proton-ge\n\thttps://github.com/GloriousEggroll/proton-ge-custom')
parser.add_argument('-d','--destination', help="Installation directory.", required=False)
parser.add_argument('-t','--temporary', help="Temporary download directory.", required=False)
parser.add_argument("version", help="Specific version to install, with standard proton-ge naming format e.g. 7-46", nargs='?', type=str, default=None) # positional version argument
args = parser.parse_args()

DOWNLOAD_DIR = "/tmp/"
PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
INSTALL_DIR = os.path.expanduser("~/.local/share/Steam/compatibilitytools.d/")
VERSION = None

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

with requests.get(PROTON_GE_GITHUB_RELEASES_URL, verify=True) as req:
    if req.status_code != 200:
        print(f"Got status code {req.status_code}", file=sys.stderr)
        sys.exit(1)
    releases_recvd = req.json()

SHA512SUM_ASSET_INDEX = 0
TAR_ASSET_INDEX = 1
if not VERSION:
    INDEX_MATCHING_VERSION_NUMBER = 0
else:
    INDEX_MATCHING_VERSION_NUMBER = None
    for index, version_map in enumerate(releases_recvd):
        if VERSION in version_map["tag_name"]:
            INDEX_MATCHING_VERSION_NUMBER = index
            break

    if not INDEX_MATCHING_VERSION_NUMBER:
        print(f"Couldn't find matching version number {VERSION} in latest 30 releases.")
        sys.exit(1)

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
if (ret := sp.run(["sha512sum", "-c", fhashname], cwd=DOWNLOAD_DIR).returncode) != 0:
    print(f"sha512sum -c {fhashname} exited with status != 0, aborting...")
    os.remove(fhashname)
    os.remove(fname)
    sys.exit(ret)

# The default python module has a significant security vulnerability:
#  see more: https://docs.python.org/3/library/tarfile.html
#with tarfile.open(fname, "r:gz") as tar:
#    tar.extractall()
#    tar.close()
#  to counter this, we're going to use the shell utility instead

print(f"Extracting {fname} ...")
if (ret := sp.run(["tar", "-xPf", fname, f"--directory={INSTALL_DIR}"], cwd=DOWNLOAD_DIR).returncode) != 0:
    print(f"tar -xvPf {fname} exited with status != 0, aborting...")
    os.remove(fhashname)
    os.remove(fname)
    sys.exit(ret)

os.remove(fname)
os.remove(fhashname)
print(f"Removed {DOWNLOAD_DIR} files {fname} & {fhashname}")
print(f"New contents are at {INSTALL_DIR}")

print("Done.")
