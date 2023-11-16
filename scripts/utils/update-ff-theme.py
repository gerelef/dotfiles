#!/usr/bin/env python3
import os
import sys
import types
import shutil
from typing import Any

import update_utils as ut
from update_utils import Filename, Release, URL

try:
    import requests
except NameError:
    print("Couldn't find requests library! Is it installed in the current environment?", file=sys.stderr)
    exit(1)


class ThemeManager(ut.Manager):

    def __init__(self, repository: URL, temp_dir: Filename, install_dirs: list[Filename], version: str = None,
                 resource_file: str = None):
        super().__init__(repository, temp_dir)
        self.install_dirs = install_dirs
        self.version = version
        self.resource_file = resource_file

    def filter(self, release: Release) -> bool:
        lower_tag_name = release.tag_name.lower()

        version_matches = True
        if self.version:
            version_matches = self.version in lower_tag_name

        return version_matches

    def get_assets(self, r: Release) -> dict[Filename, URL]:
        # there's no real "default" way to get assets
        raise NotImplemented

    def verify(self, files: list[Filename]) -> bool:
        # no repository supports checksums
        raise NotImplemented

    def install(self, files: list[Filename]):
        # there's no real "default" installation method
        raise NotImplemented

    def cleanup(self, files: list[Filename]):
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


# for blur and mono
def get_regular_assets(self: ThemeManager, r: Release) -> dict[Filename, URL]:
    td = {}
    for fn, url in r.assets.items():
        if "zip" in fn or "userChrome" in fn:
            td[fn] = url
    return td


# for gnome theme
def get_source_assets(self: ThemeManager, r: Release) -> dict[Filename, URL] | None:
    for url in r.src:
        if "zipball" in url:
            return {r.tag_name.lower(): url}
    return None


def install_gnome(self: ThemeManager, files: list[Filename]):
    zipfile = files[0]
    for destination in self.install_dirs:
        if not os.path.exists(destination):
            os.makedirs(destination)

        realpath_zipfile = os.path.join(self.download_dir, zipfile)
        unzip(realpath_zipfile, self.download_dir)
        extracted_src = [d for d in os.listdir(self.download_dir) if "rafaelmardojai-firefox-gnome-theme" in d][0]
        src_contents = os.path.join(self.download_dir, extracted_src)
        for file in os.listdir(src_contents):
            shutil.move(os.path.join(src_contents, file), os.path.join(destination, file))

        if self.resource_file:
            source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
            destination_userchrome = os.path.join(destination, "userChrome.css")
            self.log(ThemeManager.Level.PROGRESS, f"Joined {source_userchrome} to {destination_userchrome}")
            join_userchromes(source_userchrome, destination_userchrome)


def install_blur(self: ThemeManager, files: list[Filename]):
    zipfile = [fn for fn in files if ".zip" in fn][0]
    for destination in self.install_dirs:
        if not os.path.exists(destination):
            os.makedirs(destination)
        unzip(os.path.join(self.download_dir, zipfile), destination)
        if self.resource_file:
            source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
            destination_userchrome = os.path.join(destination, "userChrome.css")
            self.log(ThemeManager.Level.PROGRESS, f"Joined {source_userchrome} to {destination_userchrome}")
            join_userchromes(source_userchrome, destination_userchrome)


def install_mono(self: ThemeManager, files: list[Filename]):
    zipfile = files[0]
    for destination in self.install_dirs:
        if not os.path.exists(destination):
            os.makedirs(destination)
        unzip(os.path.join(self.download_dir, zipfile), destination)
        if self.resource_file:
            source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
            destination_userchrome = os.path.join(destination, "userChrome.css")
            self.log(ThemeManager.Level.PROGRESS, f"Joined {source_userchrome} to {destination_userchrome}")
            join_userchromes(source_userchrome, destination_userchrome)


def join_userchromes(appender: Filename, appendee: Filename):
    with open(appender, "r") as resource_file:
        with open(appendee, "a+") as main:
            main.write(resource_file.read())


def unzip(zipfile: Filename, destination):
    # unzip path/to/archive1.zip path/to/archive2.zip ... -d path/to/output
    command = ["unzip", "-o", os.path.abspath(os.path.expanduser(zipfile)), "-d", f"{destination}"]
    status, _, _ = ut.run_subprocess(command)
    if not status:
        raise RuntimeError(f"{' '.join(command)} errored! !")


def create_argparser():
    ap_builder = (
        ut.ArgumentParserBuilder(
            "Download & extract latest version of any firefox theme"
        ).add_version()
        .add_keep()
        .add_temporary()
        .add_destination()
        .add_arguments(
            flags_kwargs_dict={
                ("-r", "--resource"): {
                    "help": "Resource override file to include into UserChrome.css",
                    "required": False
                }
            }
        )
        .add_mutually_exclusive_group(
            required=True,
            flags_kwargs_dict={
                "--gnome": {
                    "help": "Download & extract latest version of firefox-gnome-theme\n"
                            "https://github.com/rafaelmardojai/firefox-gnome-theme",
                    "required": False,
                    "action": "store_true"
                },
                "--blur": {
                    "help ": "Download & extract latest version of Firefox-Mod-Blur\n"
                             "https://github.com/datguypiko/Firefox-Mod-Blur",
                    "required": False,
                    "action": "store_true"
                },
                "--mono": {
                    "help": "Download & extract latest version of mono-firefox-theme\n"
                            "https://github.com/witalihirsch/Mono-firefox-theme",
                    "required": False,
                    "action": "store_true"
                }
            }
        )
    )
    return ap_builder.build()


def get_install_dirs() -> list[str]:
    extension = "default-release"
    chrome_folder = "chrome"
    profile_path = os.path.abspath(os.path.expanduser(os.path.join("~", ".mozilla", "firefox")))
    if not os.path.exists(profile_path):
        print(f"Couldn't find {profile_path} ! Is firefox installed, or launched at least once?")
        exit(1)

    # return profile directories
    return [os.path.join(profile_path, d, chrome_folder) for d in os.listdir(profile_path) if extension in d]


MONO_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/witalihirsch/Mono-firefox-theme/releases"
GNOME_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/rafaelmardojai/firefox-gnome-theme/releases"
BLUR_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/datguypiko/Firefox-Mod-Blur/releases"
DEFAULT_INSTALL_DIRECTORIES: list[str] = get_install_dirs()
DOWNLOAD_DIR: str = "/tmp/"


def setup_argument_options(args: dict[str, Any]) -> ThemeManager:
    remote = None
    temp_dir = DOWNLOAD_DIR
    version = None
    install_dirs = DEFAULT_INSTALL_DIRECTORIES
    resource_file = None
    # pick the first version by default
    install_method = None
    get_assets_method = None
    filter_method = ThemeManager.FILTER_FIRST
    verification_method = ThemeManager.VERIFY_NOTHING
    cleanup_method = ThemeManager.cleanup

    for arg in args:
        match arg:
            case "resource":
                if args[arg]:
                    resource_file = os.path.abspath(os.path.expanduser(args[arg]))
            case "gnome":
                if args[arg]:
                    remote = GNOME_THEME_GITHUB_RELEASES_URL
                    get_assets_method = get_source_assets
                    install_method = install_gnome
            case "blur":
                if args[arg]:
                    remote = BLUR_THEME_GITHUB_RELEASES_URL
                    get_assets_method = get_regular_assets
                    install_method = install_blur
            case "mono":
                if args[arg]:
                    remote = MONO_THEME_GITHUB_RELEASES_URL
                    get_assets_method = get_regular_assets
                    install_method = install_mono
            case "destination":
                if args[arg]:
                    install_dirs = [args[arg]]
            case "temporary":
                if args[arg]:
                    temp_dir = os.path.abspath(os.path.expanduser(args[arg]))
            case "keep":
                if args[arg]:
                    cleanup_method = ThemeManager.DO_NOTHING
            case "version":
                if args[arg]:
                    filter_method = ThemeManager.filter
                    version = args[arg]
            case _:
                raise RuntimeError(f"Unknown argument {arg}")

    manager = ThemeManager(
        repository=remote,
        temp_dir=temp_dir,
        install_dirs=install_dirs,
        version=version,
        resource_file=resource_file
    )

    manager.install = types.MethodType(install_method, manager)
    manager.get_assets = types.MethodType(get_assets_method, manager)
    manager.filter = types.MethodType(filter_method, manager)
    manager.verify = types.MethodType(verification_method, manager)
    manager.cleanup = types.MethodType(cleanup_method, manager)
    return manager


if ut.euid_is_root():
    print("Do NOT run this script as root.", file=sys.stderr)
    exit(2)

if __name__ == "__main__":
    parser = create_argparser()
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
