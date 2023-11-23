#!/usr/bin/env python3
import os
import re
import sys
import types
from dataclasses import dataclass

from typing import Any, Optional

import requests

from modules import update_utils as ut


class CompatibilityManager(ut.Manager):
    @dataclass
    class Filter:
        version: Optional[str] = None
        keyword: Optional[str] = None

    SHA_CHECKSUM_REGEX = re.compile(r".*(sha[0-9][0-9]?[0-9]?sum)", flags=re.IGNORECASE & re.DOTALL)

    def __init__(self, repository: ut.URL, install_dir: ut.Filename, temp_dir: ut.Filename, _filter: Filter = Filter()):
        super().__init__(repository, temp_dir)
        self.install_dir = install_dir
        self.keyword = _filter.keyword
        self.version = _filter.version
        self.last_msg_lvl = None

    def filter(self, release: ut.Release) -> bool:
        lower_tag_name = release.name.lower()

        version_matches = True
        if self.version:
            version_matches = self.version in lower_tag_name

        keyword_matches = True
        if self.keyword:
            keyword_matches = self.keyword in lower_tag_name
        return version_matches and keyword_matches

    def get_assets(self, r: ut.Release) -> dict[ut.Filename, ut.URL]:
        items = {}
        for fname, url in r.assets.items():
            if "tar" in fname or CompatibilityManager.SHA_CHECKSUM_REGEX.match(fname):
                items[fname] = url
        return items

    def verify(self, files: list[ut.Filename]) -> bool:
        checksums = filter(lambda fn: bool(CompatibilityManager.SHA_CHECKSUM_REGEX.match(fn)), files)
        results: list[bool] = []
        for fname in checksums:
            # there should be only one match
            checksum_command = CompatibilityManager.SHA_CHECKSUM_REGEX.findall(fname)[0].lower()
            command = [checksum_command, "-c", fname]
            status, _, _ = ut.run_subprocess(command, cwd=self.download_dir)
            results.append(status)
        return False not in results

    def install(self, files: list[ut.Filename]):
        if not os.path.exists(self.install_dir):
            os.makedirs(self.install_dir)
        tars = list(map(lambda fn: os.path.join(self.download_dir, fn), filter(lambda fn: "tar" in fn, files)))
        for tarball in tars:
            command = ["tar", "-xPf", tarball, f"--directory={self.install_dir}"]
            status, _, _ = ut.run_subprocess(command, cwd=self.download_dir)
            if not status:
                raise RuntimeError(f"{' '.join(command)} errored! !")

    def cleanup(self, files: list[ut.Filename]):
        for filename in files:
            real_path = os.path.join(self.download_dir, filename)
            if os.path.exists(real_path):
                os.remove(real_path)

    def log(self, level: ut.Manager.Level, msg: str):
        # print debug info into stderr
        if level.value >= level.INFO:
            print(msg, file=sys.stderr)
            return

        if level == level.PROGRESS_BAR:
            sys.stdout.write(msg)
            return

        print(msg)


def create_argparser():
    ap_builder = (
        ut.ArgumentParserBuilder(
            "Download & extract latest version of the most popular game compatibility layers."
        )
        .add_version()
        .add_keep()
        .add_unsafe()
        .add_temporary()
        .add_mutually_exclusive_group(
            required=True,
            flags_kwargs_dict={
                ("-d", "--destination"): {
                    "help": "Install @ custom installation directory",
                    "required": False,
                    "default": None,
                    "type": str
                },
                ("--steam",): {
                    "help": f"Install @ default steam directory\n{STEAM_INSTALL_DIR}",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                },
                ("--steam-flatpak",): {
                    "help": f"Install @ default steam (flatpak) directory\n{STEAM_FLATPAK_INSTALL_DIR}",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                },
                ("--lutris",): {
                    "help": f"Install @ default lutris directory\n{LUTRIS_INSTALL_DIR}",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                },
                ("--lutris-flatpak",): {
                    "help": f"Install @ default lutris (flatpak) directory\n{LUTRIS_FLATPAK_INSTALL_DIR}",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                }
            }
        )
        .add_mutually_exclusive_group(
            required=True,
            flags_kwargs_dict={
                ("--golden-egg",): {
                    "help": "Download & extract latest version of GE-ProtonX-x\n"
                            "https://github.com/GloriousEggroll/proton-ge-custom",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                },
                ("--league",): {
                    "help": "Download & extract latest version of Lutris-GE-X.x.x-LoL\n"
                            "https://github.com/gloriouseggroll/wine-ge-custom",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                },
                ("--wine",): {
                    "help": "Download & extract latest version of Wine-GE-ProtonX-x\n"
                            "https://github.com/gloriouseggroll/wine-ge-custom",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                },
                ("--luxtorpeda",): {
                    "help": "Download & extract latest version of Luxtorpeda\n"
                            "https://github.com/luxtorpeda-dev/luxtorpeda",
                    "required": False,
                    "default": False,
                    "action": "store_true"
                }
            }
        )
    )
    return ap_builder.build()


PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
WINE_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/gloriouseggroll/wine-ge-custom/releases"
LUXTORPEDA_GITHUB_RELEASES_URL = "https://api.github.com/repos/luxtorpeda-dev/luxtorpeda/releases"
STEAM_INSTALL_DIR = os.path.expanduser(
    "~/.local/share/Steam/compatibilitytools.d/"
)
STEAM_FLATPAK_INSTALL_DIR = os.path.expanduser(
    "~/.var/app/com.valvesoftware.Valve/.local/share/Steam/compatibilitytools.d/"
)
LUTRIS_INSTALL_DIR = os.path.expanduser(
    "~/.local/share/lutris/runners/wine/"
)
LUTRIS_FLATPAK_INSTALL_DIR = os.path.expanduser(
    "~/.var/app/net.lutris.Lutris/data/lutris/runners/wine/"
)
DOWNLOAD_DIR = "/tmp/"


def setup_argument_options(args: dict[str, Any]) -> CompatibilityManager:
    remote = None
    _filter = CompatibilityManager.Filter()
    temp_dir = DOWNLOAD_DIR
    install_dir = None
    # pick the first version by default
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
                    _filter.keyword = "lol"
            case "luxtorpeda":
                if args[arg]:
                    remote = LUXTORPEDA_GITHUB_RELEASES_URL
                    verification_method = CompatibilityManager.VERIFY_NOTHING
            case "destination":
                if args[arg]:
                    install_dir = os.path.abspath(os.path.expanduser(args[arg]))
                    if not os.path.exists(install_dir):
                        os.makedirs(install_dir)
            case "steam":
                if args[arg]:
                    install_dir = STEAM_INSTALL_DIR
            case "steam_flatpak":
                if args[arg]:
                    install_dir = STEAM_FLATPAK_INSTALL_DIR
            case "lutris":
                if args[arg]:
                    install_dir = LUTRIS_INSTALL_DIR
            case "lutris_flatpak":
                if args[arg]:
                    install_dir = LUTRIS_FLATPAK_INSTALL_DIR
            case "unsafe":
                if args[arg]:
                    verification_method = CompatibilityManager.VERIFY_NOTHING
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
                    _filter.version = args[arg]
            case _:
                raise RuntimeError(f"Unknown argument {arg}")
    manager = CompatibilityManager(
        repository=remote,
        install_dir=install_dir,
        temp_dir=temp_dir,
        _filter=_filter
    )
    # these new methods need to be bound to the instance of the class in order to use self
    manager.filter = types.MethodType(filter_method, manager)
    manager.verify = types.MethodType(verification_method, manager)
    manager.cleanup = types.MethodType(cleanup_method, manager)
    return manager


if ut.euid_is_root():
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
