#!/usr/bin/env python3
import os
import argparse as ap
import update_utils as utils


def create_argparse():
    p = ap.ArgumentParser(
        description="Download & extract latest version of any firefox theme"
    )
    p.add_argument(
        "-v", "--version",
        help="specific version to install, with the standard naming format for the version to install",
        required=False,
        default=None
    )
    p.add_argument(
        "-t", "--temporary",
        help="specify temporary download directory",
        required=False
    )
    p.add_argument(
        "-s", "--source",
        help="resource file to include into main UserChrome.css",
        required=False
    )
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--gnome",
        help="Download & extract latest version of firefox-gnome-theme",
        required=False,
        action="store_true"
    )
    group.add_argument(
        "--mono",
        help="Download & extract latest version of mono-gtk-theme",
        required=False,
        action="store_true"
    )

    return p


if utils.is_root():
    print("Do NOT run this script as root.", file=sys.stderr)
    exit(2)

print("""
\033[5m
  _   _
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
\033[0m
""")

if __name__ == "__main__":
    MONO_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/witalihirsch/Mono-firefox-theme/releases"
    GNOME_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/rafaelmardojai/firefox-gnome-theme/releases"
    VIS_ROOT_DIR = os.path.expanduser("~/cloned/mono-firefox-theme")

    parser = create_argparse()
    args = parser.parse_args()
