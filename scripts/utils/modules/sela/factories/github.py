import enum
import re

from modules.sela import exceptions
from modules.sela.definitions import URL
from modules.sela.factories.abstract import ProviderFactory
from modules.sela.providers.abstract import Provider
from modules.sela.providers.branches import GitHubBranchesProvider
from modules.sela.providers.releases import GitHubReleasesProvider


class GitHubProviderFactory(ProviderFactory):
    class Regex(enum.Enum):
        GITHUB_RELEASES_API = re.compile(r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/releases/?")
        GITHUB_BRANCHES_API = re.compile(r"https://api\.github\.com/repos/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/branches/?")

    def __init__(self, url: URL):
        super().__init__(url)
        # noinspection PyTypeChecker
        self._cache: type[Provider] = None

    def create(self) -> Provider:
        if self._cache:
            return self._cache(url=self.repository)

        if GitHubProviderFactory.Regex.GITHUB_RELEASES_API.value.search(self.repository):
            self._cache = GitHubReleasesProvider
            return GitHubReleasesProvider(url=self.repository)

        if GitHubProviderFactory.Regex.GITHUB_BRANCHES_API.value.search(self.repository):
            self._cache = GitHubBranchesProvider
            return GitHubBranchesProvider(url=self.repository)

        raise exceptions.UnknownProviderException(
            f"Couldn't match repository URL to any supported provider!"
        )
