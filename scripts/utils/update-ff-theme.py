#!/usr/bin/env python3
import os
import sys
import types
import shutil
from functools import partial
from typing import Any

from modules.sela import exceptions
from modules.sela.releases.release import Release
from modules.sela.manager import Manager
from modules.sela.helpers import run_subprocess, euid_is_root
from modules.sela.arguments.builder import ArgumentParserBuilder
from modules.sela.definitions import Filename, URL

try:
    import requests
except NameError:
    print("Couldn't find requests library! Is it installed in the current environment?", file=sys.stderr)
    exit(1)


class ThemeManager(Manager):

    def __init__(self, repository: URL,
                 temp_dir: Filename,
                 install_dirs: list[Filename],
                 version: str = None,
                 resource_file: str = None):
        super().__init__(repository, temp_dir)
        self.install_dirs = install_dirs
        self.version = version
        self.resource_file = resource_file

    def filter(self, release: Release) -> bool:
        lower_tag_name = release.name.lower()

        version_matches = True
        if self.version:
            version_matches = self.version in lower_tag_name

        return version_matches

    def get_assets(self, r: Release) -> dict[Filename, URL]:
        # there's no real "default" way to get assets
        raise NotImplementedError

    def verify(self, files: list[Filename]) -> bool:
        # no repository supports checksums
        raise NotImplementedError

    def install(self, files: list[Filename]):
        # there's no real "default" installation method
        raise NotImplementedError

    def cleanup(self, files: list[Filename]):
        for filename in files:
            real_path = os.path.join(self.download_dir, filename)
            if os.path.exists(real_path):
                os.remove(real_path)

    def log(self, level: Manager.Level, msg: str):
        # print debug info into stderr
        if level.value >= level.INFO:
            print(msg, file=sys.stderr)
            return

        if level == level.PROGRESS_BAR:
            sys.stdout.write(msg)
            return

        print(msg)


# for blur, mono, gx
# noinspection PyUnusedLocal
def get_regular_assets(self: ThemeManager, r: Release) -> dict[Filename, URL]:
    td = {}
    for fn, url in r.assets.items():
        if "zip" in fn or "userChrome" in fn:
            td[fn] = url
    return td


# noinspection PyUnusedLocal
def get_keyword_uwp_assets(self: ThemeManager, r: Release, keyword) -> dict[Filename, URL]:
    td = {}
    for fn, url in r.assets.items():
        if keyword in fn.lower():
            td[fn] = url
    return td


# for gnome theme
# noinspection PyUnusedLocal
def get_source_assets(self: ThemeManager, r: Release) -> dict[Filename, URL] | None:
    for url in r.src:
        if "zipball" in url:
            return {r.name_human_readable.lower(): url}
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
        shutil.copytree(src_contents, destination, dirs_exist_ok=True)

        if self.resource_file:
            source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
            destination_userchrome = os.path.join(destination, "userChrome.css")
            self.log(ThemeManager.Level.PROGRESS, f"Joined {source_userchrome} to {destination_userchrome}")
            join_files(source_userchrome, destination_userchrome)


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
            join_files(source_userchrome, destination_userchrome)


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
            join_files(source_userchrome, destination_userchrome)


def install_gx(self: ThemeManager, files: list[Filename]):
    zipfile = files[0]
    for destination in self.install_dirs:
        if not os.path.exists(destination):
            os.makedirs(destination)

        zip_realpath = os.path.join(self.download_dir, zipfile)
        unzipped_realpath = os.path.join(self.download_dir, "firefox-gx-out")
        unzip(zip_realpath, unzipped_realpath)

        src_contents = os.path.join(unzipped_realpath, os.listdir(unzipped_realpath)[0], "chrome")
        shutil.copytree(src_contents, destination, dirs_exist_ok=True)

        if self.resource_file:
            source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
            destination_userchrome = os.path.join(destination, "userChrome.css")
            self.log(ThemeManager.Level.PROGRESS, f"Joined {source_userchrome} to {destination_userchrome}")
            join_files(source_userchrome, destination_userchrome)

        print(f"This specific theme might require a custom `user.js` in "
              f"{os.path.abspath(os.path.join(destination, ".."))}, make sure you install it manually!")


def install_ui_fix(self: ThemeManager, files: list[Filename]):
    zipfile = files[0]
    for destination in self.install_dirs:
        if not os.path.exists(destination):
            os.makedirs(destination)

        zip_realpath = os.path.join(self.download_dir, zipfile)
        unzipped_realpath = os.path.join(self.download_dir, "ui-fix-out")
        unzip(zip_realpath, unzipped_realpath)

        src_contents = os.path.join(unzipped_realpath, "chrome")
        shutil.copytree(src_contents, destination, dirs_exist_ok=True)

        if self.resource_file:
            source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
            destination_userchrome = os.path.join(destination, "userChrome.css")
            self.log(ThemeManager.Level.PROGRESS, f"Joined {source_userchrome} to {destination_userchrome}")
            join_files(source_userchrome, destination_userchrome)

        print(f"This specific theme might require a custom `user.js` in "
              f"{os.path.abspath(os.path.join(destination, ".."))}, make sure you install it manually!")


def install_uwp(self: ThemeManager, files: list[Filename]):
    raise NotImplementedError


def install_cascade(self: ThemeManager, files: list[Filename]):
    raise NotImplementedError


def join_files(appender: Filename, appendee: Filename):
    with open(appender, "r") as resource_file:
        with open(appendee, "a+") as main:
            main.write(resource_file.read())


def unzip(zipfile: Filename, destination):
    # unzip path/to/archive1.zip path/to/archive2.zip ... -d path/to/output
    command = ["unzip", "-o", os.path.abspath(os.path.expanduser(zipfile)), "-d", f"{destination}"]
    status, _, _ = run_subprocess(command)
    if not status:
        raise RuntimeError(f"{' '.join(command)} errored! !")


# noinspection PyTypeChecker
def create_argparser():
    ap_builder = (ArgumentParserBuilder("Download & extract latest version of any firefox theme")
    .add_version()
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
            ("--gnome",): {
                "help": "Download & extract latest version of firefox-gnome-theme\n"
                        "https://github.com/rafaelmardojai/firefox-gnome-theme",
                "required": False,
                "action": "store_true"
            },
            ("--blur",): {
                "help": "Download & extract latest version of Firefox-Mod-Blur\n"
                        "https://github.com/datguypiko/Firefox-Mod-Blur",
                "required": False,
                "action": "store_true"
            },
            ("--mono",): {
                "help": "Download & extract latest version of mono-firefox-theme\n"
                        "https://github.com/witalihirsch/Mono-firefox-theme",
                "required": False,
                "action": "store_true"
            },
            ("--gx",): {
                "help": "Download & extract latest version of firefox-gx\n"
                        "https://github.com/Godiesc/firefox-gx",
                "required": False,
                "action": "store_true"
            },
            ("--esr-lepton-photon",): {
                "help": "Download & extract latest version of esr-photon from firefox-ui-fix\n"
                        "https://github.com/black7375/Firefox-UI-Fix",
                "required": False,
                "action": "store_true"
            },
            ("--esr-lepton-proton",): {
                "help": "Download & extract latest version of esr-proton from firefox-ui-fix\n"
                        "https://github.com/black7375/Firefox-UI-Fix",
                "required": False,
                "action": "store_true"
            },
            ("--esr-lepton",): {
                "help": "Download & extract latest version of esr-lepton from firefox-ui-fix\n"
                        "https://github.com/black7375/Firefox-UI-Fix",
                "required": False,
                "action": "store_true"
            },
            ("--lepton-photon",): {
                "help": "Download & extract latest version of lepton-photon from firefox-ui-fix\n"
                        "https://github.com/black7375/Firefox-UI-Fix",
                "required": False,
                "action": "store_true"
            },
            ("--lepton-proton",): {
                "help": "Download & extract latest version of lepton-proton from firefox-ui-fix\n"
                        "https://github.com/black7375/Firefox-UI-Fix",
                "required": False,
                "action": "store_true"
            },
            ("--lepton",): {
                "help": "Download & extract latest version of lepton from firefox-ui-fix\n"
                        "https://github.com/black7375/Firefox-UI-Fix",
                "required": False,
                "action": "store_true"
            },
            ("--uwp",): {
                "help": "Download & extract latest version of firefox-uwp-style\n"
                        "https://github.com/Guerra24/Firefox-UWP-Style",
                "required": False,
                "action": "store_true"
            },
            ("--cascade",): {
                "help": "Download & extract latest version of cascade\n"
                        "https://github.com/andreasgrafen/cascade",
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
GX_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/Godiesc/firefox-gx/releases"
UI_FIX_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/black7375/Firefox-UI-Fix/releases"
UWP_THEME_GITHUB_BRANCHES_URL = "https://api.github.com/repos/Guerra24/Firefox-UWP-Style/branches"
CASCADE_THEME_GITHUB_BRANCHES_URL = "https://api.github.com/repos/andreasgrafen/cascade/branches"
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
            case "gx":
                if args[arg]:
                    remote = GX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = get_regular_assets
                    install_method = install_gx
            # there's alot of duplication here: there must be a smarter way to solve this...!
            case "esr_lepton_photon":
                if args[arg]:
                    remote = UI_FIX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = partial(get_keyword_uwp_assets, keyword="esr-lepton-photon")
                    install_method = install_ui_fix
            case "esr_lepton_proton":
                if args[arg]:
                    remote = UI_FIX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = partial(get_keyword_uwp_assets, keyword="esr-lepton-proton")
                    install_method = install_ui_fix
            case "esr_lepton":
                if args[arg]:
                    remote = UI_FIX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = partial(get_keyword_uwp_assets, keyword="esr-lepton.zip")
                    install_method = install_ui_fix
            case "lepton_photon":
                if args[arg]:
                    remote = UI_FIX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = partial(get_keyword_uwp_assets, keyword="lepton-photon.zip")
                    install_method = install_ui_fix
            case "lepton_proton":
                if args[arg]:
                    remote = UI_FIX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = partial(get_keyword_uwp_assets, keyword="lepton-proton.zip")
                    install_method = install_ui_fix
            case "lepton":
                if args[arg]:
                    remote = UI_FIX_THEME_GITHUB_RELEASES_URL
                    get_assets_method = partial(get_keyword_uwp_assets, keyword="lepton.zip")
                    install_method = install_ui_fix
            case "uwp":
                if args[arg]:
                    raise NotImplementedError
            case "cascade":
                if args[arg]:
                    raise NotImplementedError
                    # remote = GX_THEME_GITHUB_RELEASES_URL
                    # get_assets_method = get_regular_assets
                    # install_method = install_gx
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
        resource_file=resource_file,
    )

    manager.filter = types.MethodType(filter_method, manager)
    manager.get_assets = types.MethodType(get_assets_method, manager)
    manager.verify = types.MethodType(verification_method, manager)
    manager.install = types.MethodType(install_method, manager)
    manager.cleanup = types.MethodType(cleanup_method, manager)
    return manager


if euid_is_root():
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
    except exceptions.NoReleaseFound as e:
        print("Couldn't find a matching release! Exiting...", file=sys.stderr)
        exit(1)
    except exceptions.NoAssetsFound as e:
        print("Couldn't get assets from release! Exiting...", file=sys.stderr)
        exit(1)
    except exceptions.FileVerificationFailed as e:
        print("Couldn't verify the downloaded files! Exiting...", file=sys.stderr)
        exit(1)
    except RuntimeError as e:
        print(f"Got unknown exception {e}! Exiting...", file=sys.stderr)
        exit(1)
    except requests.RequestException as e:
        print(f"Got {e}! Is the network connection OK?", file=sys.stderr)
        exit(1)

    print("Done!")
