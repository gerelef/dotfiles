#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path

from modules.builder import ArgumentParserBuilder
from modules.sela import exceptions
from modules.sela.exceptions import FileVerificationFailed
from modules.sela.helpers import euid_is_root, run_subprocess
from modules.sela.manager import Manager
from modules.sela.stages.asset_discriminator import LambdaAssetDiscriminator
from modules.sela.stages.auditor import Auditor, NullAuditor
from modules.sela.stages.downloader import DefaultDownloader
from modules.sela.stages.installer import Installer
from modules.sela.stages.janitor import PunctualJanitor, SloppyJanitor
from modules.sela.stages.logger import StandardLogger
from modules.sela.stages.release_discriminator import KeywordReleaseDiscriminator, FirstReleaseDiscriminator

try:
    import requests
except NameError:
    print("Couldn't find requests library! Is it installed in the current environment?", file=sys.stderr)
    exit(1)

SHA_CHECKSUM_REGEX = re.compile(r".*(sha[0-9][0-9]?[0-9]?sum)", flags=re.IGNORECASE & re.DOTALL)
logger = StandardLogger()


class ChecksumAuditor(Auditor):
    def verify(self, files: list[Path]) -> None:
        if not files:
            return

        download_dir = files[0].parent.absolute()
        files_to_check: list[Path] = filter(lambda fnp: bool(SHA_CHECKSUM_REGEX.match(fnp.name)), files)
        results: list[bool] = []
        for matched_file in files_to_check:
            # there should be only one match
            checksum_command = SHA_CHECKSUM_REGEX.findall(matched_file.name)[0].lower()
            command = [checksum_command, "-c", matched_file.name]
            status, _, _ = run_subprocess(command, cwd=download_dir)
            results.append(status)

        if not all(results):
            failed = list(filter(lambda e: not e, results))
            raise FileVerificationFailed(f"Couldn't verify {failed} !")


class RegularInstaller(Installer):
    def __init__(self, destination: Path):
        self.target = destination

    def install(self, files: list[Path]) -> None:
        if not self.target.exists(follow_symlinks=False):
            self.target.mkdir(mode=0o740, parents=True, exist_ok=True)
        if not self.target.is_dir():
            raise ValueError()

        # FIXME
        # https://docs.python.org/3/library/tarfile.html#tarfile-extraction-filter
        tars: list[Path] = list(filter(lambda fnp: "tar" in fnp.name, files))
        for tarball in tars:
            command = ["tar", "-xPf", tarball.absolute(), f"--directory={self.target.absolute()}"]
            status, _, _ = run_subprocess(command, cwd=tarball.parent)
            if not status:
                raise RuntimeError(f"{' '.join(command)} errored!!")


# noinspection PyTypeChecker
def create_argparser():
    ap_builder = (ArgumentParserBuilder("Download & extract latest version of numerous game compatibility layers.")
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
            ("--golden-egg", "--proton-ge"): {
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
    ))
    return ap_builder.build()


def get_manager(args: argparse.Namespace) -> Manager:
    keywords: list[str] = []

    def get_remote(args) -> tuple[str, Auditor]:
        nonlocal keywords
        # noinspection PyTypeChecker
        remote: str = None
        # noinspection PyTypeChecker
        auditor: Auditor = None
        if args.golden_egg or args.proton_ge:
            remote = PROTON_GE_GITHUB_RELEASES_URL
            auditor = ChecksumAuditor()
        if args.wine:
            remote = WINE_GE_GITHUB_RELEASES_URL
            auditor = ChecksumAuditor()
        if args.league:
            remote = WINE_GE_GITHUB_RELEASES_URL
            keywords.append("lol")  # ugly solution, but still more elegant than the alternatives
            auditor = ChecksumAuditor()
        if args.luxtorpeda:
            remote = LUXTORPEDA_GITHUB_RELEASES_URL
            auditor = NullAuditor()
        if args.unsafe:
            auditor = NullAuditor()
        return remote, auditor

    def get_destination(args) -> Path:
        install_dir = None
        if args.destination:
            install_dir = Path(args.destination).expanduser().absolute()
            if not install_dir.exists():
                install_dir.mkdir(0o740, parents=True, exist_ok=True)
        if args.steam:
            install_dir = STEAM_INSTALL_DIR
        if args.steam_flatpak:
            install_dir = STEAM_FLATPAK_INSTALL_DIR
        if args.lutris:
            install_dir = LUTRIS_INSTALL_DIR
        if args.lutris_flatpak:
            install_dir = LUTRIS_FLATPAK_INSTALL_DIR
        return install_dir

    remote, auditor = get_remote(args)
    install_dir = get_destination(args)

    temp_dir = DOWNLOAD_DIR
    if args.temporary:
        temp_dir = Path(args.temporary).expanduser().absolute()
        if not temp_dir.exists():
            temp_dir.mkdir(0o700, parents=True, exist_ok=True)

    if args.version:
        keywords.append(args.version)

    janitor = PunctualJanitor()
    if args.keep:
        janitor = SloppyJanitor()

    rdiscriminator = FirstReleaseDiscriminator()
    if keywords:
        rdiscriminator = KeywordReleaseDiscriminator(
            *keywords,
            preprocess=lambda s: s.lower(),
            strict=True
        )

    manager = Manager(remote)
    manager.submit_release_discriminator(rdiscriminator)
    manager.submit_asset_discriminator(
        LambdaAssetDiscriminator(
            lambda fn, url: "tar" in fn and url is not None,
            lambda fn, url: SHA_CHECKSUM_REGEX.match(fn) and url is not None,
            strict=False
        )
    )
    manager.submit_downloader(DefaultDownloader(logger, manager.provider, temp_dir))
    manager.submit_auditor(auditor)
    manager.submit_installer(RegularInstaller(install_dir))
    manager.submit_janitor(janitor)
    manager.submit_logger(logger)

    return manager


PROTON_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
WINE_GE_GITHUB_RELEASES_URL = "https://api.github.com/repos/gloriouseggroll/wine-ge-custom/releases"
LUXTORPEDA_GITHUB_RELEASES_URL = "https://api.github.com/repos/luxtorpeda-dev/luxtorpeda/releases"
STEAM_INSTALL_DIR = Path("~/.local/share/Steam/compatibilitytools.d/").expanduser().absolute()
LUTRIS_INSTALL_DIR = Path("~/.local/share/lutris/runners/wine/").expanduser().absolute()
LUTRIS_FLATPAK_INSTALL_DIR = Path("~/.var/app/net.lutris.Lutris/data/lutris/runners/wine/").expanduser().absolute()
STEAM_FLATPAK_INSTALL_DIR = Path(
    "~/.var/app/com.valvesoftware.Valve/.local/share/Steam/compatibilitytools.d/"
).expanduser().absolute()
DOWNLOAD_DIR = Path("/tmp/").absolute()

if __name__ == "__main__":
    if euid_is_root():
        print("Do NOT run this script as root!", file=sys.stderr)
        exit(2)

    parser = create_argparser()
    compat_manager = get_manager(parser.parse_args())

    print("\033[5m", end="")
    print(r"""
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
    """)
    print("\033[0m", end="")

    try:
        compat_manager.run()
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
