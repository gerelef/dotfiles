from typing import override

from modules.sela import exceptions
from modules.sela.definitions import URL
from modules.sela.factories.abstract import ProviderFactory
from modules.sela.providers.abstract import Provider
from modules.sela.providers.github.nightly import GitHubNightlyProvider
from modules.sela.providers.github.releases import GitHubReleasesProvider


class GitHubProviderFactory(ProviderFactory):

    def __init__(self, url: URL):
        super().__init__(url)
        # noinspection PyTypeChecker
        self._cache: type[Provider] = None

    @override
    def create(self) -> Provider:
        if self._cache:
            return self._cache(url=self.repository)

        if GitHubReleasesProvider.match(self.repository):
            self._cache = GitHubReleasesProvider
            return GitHubReleasesProvider(url=self.repository)

        if GitHubNightlyProvider.match(self.repository):
            self._cache = GitHubNightlyProvider
            return GitHubNightlyProvider(url=self.repository)

        raise exceptions.UnknownProviderException(f"Couldn't match repository URL to any supported provider!")
