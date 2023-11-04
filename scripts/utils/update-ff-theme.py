#!/usr/bin/env python3
import sys
from typing import Any

import update_utils as ut
from update_utils import Filename, Release, URL

try:
    import requests
except NameError:
    print("Couldn't find requests library! Is it installed in the current environment?", file=sys.stderr)
    exit(1)


class ThemeManager(ut.Manager):

    def filter(self, release: Release) -> bool:
        pass

    def get_assets(self, r: Release) -> dict[Filename, URL]:
        pass

    def verify(self, files: list[Filename]) -> bool:
        pass

    def install(self, files: list[Filename]):
        pass

    def cleanup(self, files: list[Filename]):
        pass

    def log(self, level: ut.Manager.Level, msg: str):
        pass


def create_argparse():
    p = ut.get_default_argparser(
        description="Download & extract latest version of any firefox theme"
    )
    p.add_argument(
        "--resource",
        help="Resource override file to include into UserChrome.css",
        required=False
    )
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--gnome",
        help="Download & extract latest version of firefox-gnome-theme\n"
             "\thttps://github.com/rafaelmardojai/firefox-gnome-theme",
        required=False,
        action="store_true"
    )
    group.add_argument(
        "--mono",
        help="Download & extract latest version of mono-firefox-theme\n"
             "\thttps://github.com/witalihirsch/Mono-firefox-theme",
        required=False,
        action="store_true"
    )

    return p


MONO_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/witalihirsch/Mono-firefox-theme/releases"
GNOME_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/rafaelmardojai/firefox-gnome-theme/releases"
# TODO add default profile folder $HOME/.mozilla/firefox/######.default-release/
# TODO add blur https://github.com/datguypiko/Firefox-Mod-Blur


def setup_argument_options(args: dict[str, Any]) -> ThemeManager:
    pass


if ut.euid_is_root():
    print("Do NOT run this script as root.", file=sys.stderr)
    exit(2)

if __name__ == "__main__":
    parser = create_argparse()
    theme_manager = setup_argument_options(vars(parser.parse_args()))

    print("""
\033[5m
  _   _
 | | | |                                                                  
 | |_| |__   ___ _ __ ___   ___                                           
 | __| '_ \\ / _ \\ '_ ` _ \\ / _ \\                                          
 | |_| | | |  __/ | | | | |  __/                                          
  \\__|_| |_|\\___|_| |_| |_|\\___|__ ___   __ _ _ __   __ _  __ _  ___ _ __ 
                             | '_ ` _ \\ / _` | '_ \\ / _` |/ _` |/ _ \\ '__|
                             | | | | | | (_| | | | | (_| | (_| |  __/ |   
                             |_| |_| |_|\\__,_|_| |_|\\__,_|\\__, |\\___|_|   
                                                           __/ |          
                                                          |___/
\033[0m
    """)

    try:
        theme_manager.run()
    except KeyboardInterrupt:
        print("Aborted by user. Exiting...")
        exit(130)
    except ut.Exceptions.NoReleaseFound as e:
        print("Couldn't find a matching release! Exiting...", file=sys.stderr)
        exit(1)
    except ut.Exceptions.NoAssetsFound as e:
        print("Couldn't get assets from release! Exiting...", file=sys.stderr)
        exit(1)
    except ut.Exceptions.FileVerificationFailed as e:
        print("Couldn't verify the downloaded files! Exiting...", file=sys.stderr)
        exit(1)
    except RuntimeError as e:
        print(f"Got unknown exception {e}! Exiting...", file=sys.stderr)
        exit(1)
    except requests.RequestException as e:
        print(f"Got {e}! Is the network connection OK?", file=sys.stderr)
        exit(1)

    print("Done!")
