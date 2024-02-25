#!/usr/bin/env python3
import argparse
import os
# noinspection PyUnresolvedReferences
import readline
import shutil
import sys
from pathlib import Path
from typing import Optional, override
from zipfile import ZipFile

from modules.builder import ArgumentParserBuilder
from modules.sela import exceptions
from modules.sela.definitions import Filename, URL
from modules.sela.helpers import euid_is_root
from modules.sela.manager import Manager
from modules.sela.releases.abstract import Release
from modules.sela.stages.asset_discriminator import AssetDiscriminator
from modules.sela.stages.auditor import Auditor, NullAuditor
from modules.sela.stages.downloader import DefaultDownloader
from modules.sela.stages.installer import Installer
from modules.sela.stages.janitor import Janitor, SloppyJanitor, PunctualJanitor
from modules.sela.stages.logger import StandardLogger
from modules.sela.stages.release_discriminator import ReleaseDiscriminator, FirstReleaseDiscriminator, \
    SimpleMatchDiscriminator

# global logger
logger = StandardLogger()


# @final
# class ThemeManager(Manager):
#
#     def __init__(self, repository: URL,
#                  temp_dir: Filename,
#                  install_dirs: list[Filename],
#                  version: str = None,
#                  resource_file: str = None):
#         super().__init__(repository, download_dir=temp_dir)
#         self.install_dirs = install_dirs
#         self.version = version
#         self.resource_file = resource_file
#
#     @override
#     def filter(self, release: Release) -> bool:
#         lower_tag_name = release.name.lower()
#
#         version_matches = True
#         if self.version:
#             version_matches = self.version in lower_tag_name
#
#         return version_matches

def join_txt_contents(appender: Filename, appendee: Filename):
    with open(appender, "r") as source:
        with open(appendee, "a+") as target:
            target.write(source.read())


# for blur, mono, gx
class ZipUserChromeAssetDiscriminator(AssetDiscriminator):
    @override
    def discriminate(self, release: Release) -> dict[Filename, URL]:
        td = {}
        for fn, url in release.assets.items():
            if "zip" in fn or "userChrome" in fn:
                td[fn] = url
        return td


class KeywordAssetDiscriminator(AssetDiscriminator):
    def __init__(self, *kws: str):
        self.keywords = kws

    @override
    def discriminate(self, release: Release) -> dict[Filename, URL]:
        td = {}
        for fn, url in release.assets.items():
            for kw in self.keywords:
                if kw in fn.lower():
                    td[fn] = url
        return td


# for gnome theme
class SourceAssetDiscriminator(AssetDiscriminator):
    @override
    def discriminate(self, release: Release) -> Optional[dict[Filename, URL]]:
        for url in release.src:
            if "zipball" in url:
                return {release.name_human_readable.lower(): url}
        return None


class GnomeInstaller(Installer):
    def __init__(self, install_dirs, resource_file):
        self.install_dirs = install_dirs
        self.resource_file = resource_file

    @override
    def install(self, files: list[Path]) -> None:
        zipfile = files[0]
        for destination in self.install_dirs:
            chrome_dir = os.path.join(destination, "chrome")
            if not os.path.exists(chrome_dir):
                os.makedirs(chrome_dir)

            download_dir = zipfile.parent
            with ZipFile(zipfile) as fzip:
                fzip.extractall(path=download_dir)
            extracted_src = [d for d in os.listdir(download_dir) if "rafaelmardojai-firefox-gnome-theme" in d][0]

            src_contents = os.path.join(download_dir, extracted_src)
            shutil.copytree(src_contents, chrome_dir, dirs_exist_ok=True)

            if self.resource_file:
                source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
                destination_userchrome = os.path.join(chrome_dir, "userChrome.css")
                logger.progress(f"Joined {source_userchrome} to {destination_userchrome}")
                join_txt_contents(source_userchrome, destination_userchrome)


class BlurInstaller(Installer):
    def __init__(self, install_dirs, resource_file):
        self.install_dirs = install_dirs
        self.resource_file = resource_file

    @override
    def install(self, files: list[Path]) -> None:
        zipfile = [fn for fn in files if ".zip" in fn][0]
        for destination in self.install_dirs:
            chrome_dir = os.path.join(destination, "chrome")
            if not os.path.exists(chrome_dir):
                os.makedirs(chrome_dir)

            with ZipFile(zipfile) as fzip:
                fzip.extractall(path=chrome_dir)
            if self.resource_file:
                source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
                destination_userchrome = os.path.join(chrome_dir, "userChrome.css")
                logger.progress(f"Joined {source_userchrome} to {destination_userchrome}")
                join_txt_contents(source_userchrome, destination_userchrome)


class MonoInstaller(Installer):
    def __init__(self, install_dirs, resource_file):
        self.install_dirs = install_dirs
        self.resource_file = resource_file

    @override
    def install(self, files: list[Path]) -> None:
        zipfile = files[0]
        for destination in self.install_dirs:
            chrome_dir = os.path.join(destination, "chrome")
            if not os.path.exists(chrome_dir):
                os.makedirs(chrome_dir)

            with ZipFile(zipfile) as fzip:
                fzip.extractall(path=chrome_dir)
            if self.resource_file:
                source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
                destination_userchrome = os.path.join(chrome_dir, "userChrome.css")
                logger.progress(f"Joined {source_userchrome} to {destination_userchrome}")
                join_txt_contents(source_userchrome, destination_userchrome)


class GXInstaller(Installer):
    def __init__(self, install_dirs, resource_file):
        self.install_dirs = install_dirs
        self.resource_file = resource_file

    @override
    def install(self, files: list[Path]) -> None:
        zipfile = files[0]
        for destination in self.install_dirs:
            chrome_dir = os.path.join(destination, "chrome")
            if not os.path.exists(chrome_dir):
                os.makedirs(chrome_dir)

            download_dir = zipfile.parent
            unzipped_realpath = os.path.join(download_dir, "firefox-gx-out")
            with ZipFile(zipfile) as fzip:
                fzip.extractall(path=unzipped_realpath)

            src_contents = os.path.join(unzipped_realpath, os.listdir(unzipped_realpath)[0], "chrome")
            shutil.copytree(src_contents, chrome_dir, dirs_exist_ok=True)

            if self.resource_file:
                source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
                destination_userchrome = os.path.join(chrome_dir, "userChrome.css")
                logger.progress(f"Joined {source_userchrome} to {destination_userchrome}")
                join_txt_contents(source_userchrome, destination_userchrome)

            print(f"This specific theme might require a custom `user.js` in {destination}, "
                  f"make sure you install it manually!")


class UIFixInstaller(Installer):
    def __init__(self, install_dirs, resource_file):
        self.install_dirs = install_dirs
        self.resource_file = resource_file

    @override
    def install(self, files: list[Path]) -> None:
        zipfile = files[0]
        for destination in self.install_dirs:
            chrome_dir = os.path.join(destination, "chrome")
            if not os.path.exists(chrome_dir):
                os.makedirs(chrome_dir)

            download_dir = zipfile.parent
            unzipped_realpath = os.path.join(download_dir, "ui-fix-out")
            with ZipFile(zipfile) as fzip:
                fzip.extractall(path=unzipped_realpath)

            src_contents = os.path.join(unzipped_realpath, "chrome")
            shutil.copytree(src_contents, chrome_dir, dirs_exist_ok=True)

            if self.resource_file:
                source_userchrome = os.path.abspath(os.path.expanduser(self.resource_file))
                destination_userchrome = os.path.join(chrome_dir, "userChrome.css")
                logger.progress(f"Joined {source_userchrome} to {destination_userchrome}")
                join_txt_contents(source_userchrome, destination_userchrome)

            print(f"This specific theme might require a custom `user.js` in {destination}, "
                  f"make sure you install it manually!")


class UWPInstaller(Installer):
    @override
    def install(self, files: list[Path]) -> None:
        raise NotImplementedError


class CascadeInstaller(Installer):
    @override
    def install(self, files: list[Path]) -> None:
        raise NotImplementedError


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
    profile_path = os.path.abspath(os.path.expanduser(os.path.join("~", ".mozilla", "firefox")))
    if not os.path.exists(profile_path):
        print(f"Couldn't find \"{profile_path}\" ! Is firefox installed, or launched at least once?")
        exit(1)

    return [os.path.join(profile_path, d) for d in os.listdir(profile_path) if extension in d]


MONO_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/witalihirsch/Mono-firefox-theme/releases"
GNOME_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/rafaelmardojai/firefox-gnome-theme/releases"
BLUR_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/datguypiko/Firefox-Mod-Blur/releases"
GX_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/Godiesc/firefox-gx/releases"
UI_FIX_THEME_GITHUB_RELEASES_URL = "https://api.github.com/repos/black7375/Firefox-UI-Fix/releases"
UWP_THEME_GITHUB_BRANCHES_URL = "https://api.github.com/repos/Guerra24/Firefox-UWP-Style/branches"
CASCADE_THEME_GITHUB_BRANCHES_URL = "https://api.github.com/repos/andreasgrafen/cascade/branches"
DEFAULT_INSTALL_DIRECTORIES: list[str] = get_install_dirs()
DOWNLOAD_DIR: str = "/tmp/"


def setup_argument_options(args: argparse.Namespace) -> Manager:
    rdiscriminator: ReleaseDiscriminator = FirstReleaseDiscriminator()
    auditor: Auditor = NullAuditor()
    janitor: Janitor = PunctualJanitor()
    # these two have no defaults and need to be set accordingly from required flags
    # noinspection PyTypeChecker
    adiscriminator: AssetDiscriminator = None
    # noinspection PyTypeChecker
    installer: Installer = None

    install_dirs = DEFAULT_INSTALL_DIRECTORIES
    if args.destination:
        install_dirs = args.destination
    temp_dir = DOWNLOAD_DIR
    if args.temporary:
        temp_dir = os.path.abspath(os.path.expanduser(args.temporary))
    if args.version:
        rdiscriminator = SimpleMatchDiscriminator(args.version)
    resource_file = None
    if args.resource:
        resource_file = args.resource
    remote = None
    if args.gnome:
        remote = GNOME_THEME_GITHUB_RELEASES_URL
        adiscriminator = SourceAssetDiscriminator()
        installer = GnomeInstaller(install_dirs, resource_file)
    if args.blur:
        remote = BLUR_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("zip", "userChrome")
        installer = BlurInstaller(install_dirs, resource_file)
    if args.mono:
        remote = MONO_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("zip", "userChrome")
        installer = MonoInstaller(install_dirs, resource_file)
    if args.gx:
        remote = GX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("zip", "userChrome")
        installer = GXInstaller(install_dirs, resource_file)
    if args.esr_lepton_photon:
        remote = UI_FIX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("esr-lepton-photon")
        installer = UIFixInstaller(install_dirs, resource_file)
    if args.esr_lepton_proton:
        remote = UI_FIX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("esr-lepton-proton")
        installer = UIFixInstaller(install_dirs, resource_file)
    if args.esr_lepton:
        remote = UI_FIX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("esr-lepton.zip")
        installer = UIFixInstaller(install_dirs, resource_file)
    if args.lepton_photon:
        remote = UI_FIX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("lepton-photon.zip")
        installer = UIFixInstaller(install_dirs, resource_file)
    if args.lepton_proton:
        remote = UI_FIX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("lepton-proton.zip")
        installer = UIFixInstaller(install_dirs, resource_file)
    if args.lepton:
        remote = UI_FIX_THEME_GITHUB_RELEASES_URL
        adiscriminator = KeywordAssetDiscriminator("lepton.zip")
        installer = UIFixInstaller(install_dirs, resource_file)
    if args.uwp:
        raise NotImplementedError
    if args.cascade:
        raise NotImplementedError
    if args.keep:
        janitor: Janitor = SloppyJanitor()
    manager = Manager(remote)
    manager.submit_release_discriminator(rdiscriminator)
    manager.submit_asset_discriminator(adiscriminator)
    manager.submit_downloader(DefaultDownloader(logger, manager.provider, temp_dir))
    manager.submit_auditor(auditor)
    manager.submit_installer(installer)
    manager.submit_janitor(janitor)
    return manager


if __name__ == "__main__":
    if euid_is_root():
        print("Do NOT run this script as root.", file=sys.stderr)
        exit(2)

    parser = create_argparser()
    theme_manager = setup_argument_options(parser.parse_args())

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

    print("Done!")
