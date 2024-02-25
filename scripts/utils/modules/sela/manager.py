from abc import ABC
from pathlib import Path
from typing import Self, final

from modules.sela import exceptions
from modules.sela.definitions import URL
from modules.sela.exceptions import UnsuccessfulRequest
from modules.sela.factories.abstract import ProviderFactory
from modules.sela.helpers import auto_str
from modules.sela.providers.abstract import Provider
from modules.sela.stages.asset_discriminator import AssetDiscriminator, AllInclusiveAssetDiscriminator
from modules.sela.stages.auditor import Auditor, NullAuditor
from modules.sela.stages.downloader import Downloader, DefaultDownloader
from modules.sela.stages.installer import Installer
from modules.sela.stages.janitor import Janitor, SloppyJanitor
from modules.sela.stages.logger import Logger, StandardLogger
from modules.sela.stages.release_discriminator import ReleaseDiscriminator, FirstReleaseDiscriminator


@auto_str
@final
class Manager(ABC):
    """
    The main Manager class. This class serves as the sole entry point to the framework. In order to use,
    instantiate with the appropriate stage directors and call .run(). There is a default implementation for every step,
    providing a very barebones experience, however it'll most likely not fit your own specific needs.
    Most of theprocess is automated & encapsulated to prevent accidental tampering, however you can easily extend
    this with very custom functionality, starting with a custom ProviderFactory instance.
    The internals should be well documented, and pretty simple to understand; I'll try my best to write complete
    documentation any time I get. If you think some documentation is incomplete, or an implementation is not clear-cut,
    open an issue, so we can talk about it.
    """

    # noinspection PyTypeChecker
    def __init__(self, repository: URL):
        """
        :param repository: direct URL to the repository to make requests
        :raises FileNotFoundError: raised if download_dir doesn't exist, or not enough permissions to execute os.stat(d)
        """
        self.repository = repository

        self.pfactory_cls: type[ProviderFactory] = ProviderFactory
        self.released: ReleaseDiscriminator = None
        self.assetd: AssetDiscriminator = None
        self.downloader: Downloader = None
        self.auditor: Auditor = None
        self.installer: Installer = None
        self.janitor: Janitor = None

        # cached
        self.pfactory: ProviderFactory = None
        self.__provider = None

    def run(self) -> None:
        """
        Runs the submitted stages.
        :raises UnsuccessfulRequest: raised when a critical request errored
        :raises exceptions.NoReleaseFound: raised when no release matched
        :raises exceptions.NoAssetsFound: raised when no assets are available/returned
        :raises exceptions.FileVerificationFailed: raised when file verification failed
        :raises requests.JSONDecodeError: raised when there's malformed JSON in the response
        :raises requests.ConnectionError:
        :raises requests.Timeout:
        :raises requests.TooManyRedirects:
        """
        downloaded: list[Path] = []
        try:
            status, r = self.provider.get_release(self.released.discriminate)
            if not status.is_successful():
                raise UnsuccessfulRequest("Couldn't get release from remote!", status)

            downloadables = self.assetd.discriminate(r)
            if not downloadables:
                raise exceptions.NoAssetsFound("No assets found, or matched! Is everything OK?")

            downloaded = self.downloader.download(downloadables)
            self.auditor.verify(downloaded)
            self.installer.install(downloaded)
        finally:
            self.janitor.cleanup(downloaded)

    def submit_factory(self, pfactory_cls: type[ProviderFactory]):
        """
        Submits the provider factory class, responsible for creating the appropriate provider.
        """
        self.pfactory_cls = pfactory_cls
        self.pfactory = None

    def submit_release_discriminator(self, rd: ReleaseDiscriminator):
        """
        Submits the release discriminator, responsible for picking a valid release.
        """
        self.released = rd

    def submit_asset_discriminator(self, ad: AssetDiscriminator):
        """
        Submits the asset discriminator, responsible for picking the valid assets from a release.
        """
        self.assetd = ad

    def submit_downloader(self, downloader: Downloader):
        """
        Submits the downloader, responsible for downloading said release.
        """
        self.downloader = downloader

    def submit_auditor(self, auditor: Auditor):
        """
        Submits the auditor, responsible for auditing the files' integrity.
        """
        self.auditor = auditor

    def submit_installer(self, installer: Installer):
        """
        Submits the installer, responsible for installing the files.
        """
        self.installer = installer

    def submit_janitor(self, janitor: Janitor):
        """
        Submits the janitor, responsible for clean up, post-install, or if a fatal occurs.
        """
        self.janitor = janitor

    @property
    def provider(self) -> Provider:
        if not self.pfactory_cls:
            raise RuntimeError("provider factory class is undefined?!")

        if not self.pfactory:
            self.__provider = self.pfactory_cls(self.repository).create()

        return self.__provider

    @classmethod
    def get_default_manager(cls, repository: URL, logger: Logger = None) -> Self:
        """
        Creates a manager instance with all the defaults.
        Default director which are submitted (in order):
            StandardLogger
            ProviderFactory (internally)
            FirstReleaseDiscriminator
            AllInclusiveAssetDiscriminator
            DefaultDownloader
            NullAuditor
            SloppyJanitor
        You may override specific steps with .submit_stage(director).
        """
        if logger is None:
            logger = StandardLogger()

        manager = Manager(repository)
        manager.submit_release_discriminator(FirstReleaseDiscriminator())
        manager.submit_asset_discriminator(AllInclusiveAssetDiscriminator())
        manager.submit_downloader(DefaultDownloader(logger, manager.provider))
        manager.submit_auditor(NullAuditor())
        manager.submit_janitor(SloppyJanitor())

        return manager
