#!/usr/bin/env python3
import requests
import urllib.request
import json
import sys
import os
import subprocess as sp
import argparse as ap

print("""

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
   
""")

def filter_fname(fn):
    return fn.replace("\\", "").replace("-", "").replace(" ", "-")

if os.geteuid() == 0:
    print("Do NOT run this script as root.", file=sys.stderr)
    sys.exit(1)

PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
INSTALL_DIR = os.path.expanduser("~/.local/share/Steam/compatibilitytools.d/")

parser = ap.ArgumentParser(description='Download & extract latest version of proton-ge\n\thttps://github.com/GloriousEggroll/proton-ge-custom')
parser.add_argument('-d','--destination', help="Destination to extract stuff", required=False)
args = parser.parse_args()

if args.destination:
    INSTALL_DIR = os.path.expanduser(args.destination)

with requests.get(PROTON_GE_GITHUB_RELEASES_URL, verify=True) as req:
    if req.status_code == 200:
        releases_recvd = req.json()
    else:
        print(f"Got status code {req.status_code}", file=sys.stderr)
        sys.exit(1)

# https://stackoverflow.com/questions/24346872/python-equivalent-of-a-given-wget-command
fname = "/tmp/" + filter_fname(releases_recvd[0]["name"]+".tar.gz")
tarball_url = releases_recvd[0]["assets"][1]["browser_download_url"]
with requests.get(tarball_url, verify=True, allow_redirects=True) as req:
    with open(fname, 'wb') as out:
        print(f"Writing {fname} from url {tarball_url}")
        out.write(req.content)
        
print("Done.")

# This has a security vulnerability:
#    see more: https://docs.python.org/3/library/tarfile.html
#    to counter this, we're going to use the shell utility instead
#with tarfile.open(fname, "r:gz") as tar:
#    tar.extractall()
#    tar.close()

if not os.path.exists(INSTALL_DIR):
    os.makedirs(INSTALL_DIR)

print(f"Extracting {fname} ...")
if (ret := sp.run(["tar", "-xPf", fname, f"--directory={INSTALL_DIR}"]).returncode) != 0:
    print(f"tar -xvPf {fname} exited with status != 0, aborting...")
    os.remove(fname)
    sys.exit(ret)

print(f"Finished, new contents are at {INSTALL_DIR}")

