#!/usr/bin/env python3
import requests
import urllib.request
import json
import sys
import os
import subprocess as sp
import argparse as ap

print("""

                __  __  ____  _   _  ____     __  __                      
               |  \/  |/ __ \| \ | |/ __ \   / _|/ _|                     
               | \  / | |  | |  \| | |  | | | |_| |_                      
               | |\/| | |  | | . ` | |  | | |  _|  _|                     
               | |  | | |__| | |\  | |__| | | | | |                       
               |_|  |_|\____/|_| \_|\____/  |_| |_|                       
  ______ ______ ______ ______ ______ ______                               
 |______|______|______|______|______|______|                              
 | | | |                                                                  
 | |_| |__   ___ _ __ ___   ___                                           
 | __| '_ \ / _ \ '_ ` _ \ / _ \                                          
 | |_| | | |  __/ | | | | |  __/                                          
  \__|_| |_|\___|_| |_| |_|\___|__ ___   __ _ _ __   __ _  __ _  ___ _ __ 
                             | '_ ` _ \ / _` | '_ \ / _` |/ _` |/ _ \ '__|
                             | | | | | | (_| | | | | (_| | (_| |  __/ |   
                             |_| |_| |_|\__,_|_| |_|\__,_|\__, |\___|_|   
                                                           __/ |          
                                                          |___/           

""")

def filter_fname(fn):
    return fn.replace("\\", "").replace("-", "").replace(" ", "-")

if __name__ == "__main__":
    if os.geteuid() == 0:
        print("Do NOT run this script as root.", file=sys.stderr)
        sys.exit(1)

    MONO_FF_GITHUB_RELEASES_URL = "https://api.github.com/repos/witalihirsch/Mono-firefox-theme/releases"
    VIS_ROOT_DIR = os.path.expanduser("~/cloned/mono-firefox-theme")
    DOT_ROOT_DIR = os.path.expanduser("~/dotfiles/.config/mozilla")
    
    ####################### ARGPARSE #######################
    parser = ap.ArgumentParser(description='Download & extract latest version of mono-firefox-theme (https://github.com/witalihirsch/Mono-firefox-theme)')
    parser.add_argument('-s','--source', help='Source of dotfile to copy into new mono-ff-theme userchrome.css', required=False)
    parser.add_argument('-d','--destination', help="Destination to extract stuff", required=False)
    args = parser.parse_args()
    if args.source:
        DOT_ROOT_DIR = os.path.expanduser(args.source)
    if args.destination:
        VIS_ROOT_DIR = os.path.expanduser(args.destination)
    
    # get the latest releases from github
    with requests.get(MONO_FF_GITHUB_RELEASES_URL, verify=True) as req:
        if req.status_code == 200:
            releases_recvd = req.json()
        else:
            print(f"Got status code {req.status_code}", file=sys.stderr)
            sys.exit(1)

    # https://stackoverflow.com/questions/24346872/python-equivalent-of-a-given-wget-command
    fname = "/tmp/" + filter_fname(releases_recvd[0]["name"]+".tar.xz")
    tarball_url = releases_recvd[0]["assets"][0]["browser_download_url"]
    with requests.get(tarball_url, verify=True, allow_redirects=True) as req:
        with open(fname, 'wb') as out:
            print(f"Writing {fname} from url {tarball_url}")
            out.write(req.content)
            
    print("Done.")

    # This has a security vulnerability:
    #    see more: https://docs.python.org/3/library/tarfile.html
    #with tarfile.open(fname, "r:gz") as tar:
    #    tar.extractall()
    #    tar.close()

    if not os.path.exists(VIS_ROOT_DIR):
        os.makedirs(VIS_ROOT_DIR)
    print(f"Extracting {fname} ...")
    if (ret := sp.run(["tar", "-xPf", fname, f"--directory={VIS_ROOT_DIR}"]).returncode) != 0:
        print(f"tar -xvPf {fname} exited with status != 0, aborting...")
        os.remove(fname)
        sys.exit(ret)

    try:
        print(f"Copying from {DOT_ROOT_DIR}/userChrome.css to {DOT_ROOT_DIR}/userChrome.css")
        with open(f"{DOT_ROOT_DIR}/userChrome.css", "r") as dt_userchrome:
            with open(f"{VIS_ROOT_DIR}/userChrome.css", "a+") as mo_userchrome:
                mo_userchrome.write(dt_userchrome.read())
    except Exception as e:
        print(f"Got {e} while trying to copy from source {DOT_ROOT_DIR}/userChrome.css to dest {VIS_ROOT_DIR}/userChrome.css")
        sys.exit(1)

    print(f"Finished, new contents are at {VIS_ROOT_DIR}")

