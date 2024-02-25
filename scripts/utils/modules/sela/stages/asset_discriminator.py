from abc import ABC, abstractmethod
from typing import override

from modules.sela.definitions import Filename, URL
from modules.sela.releases.abstract import Release


class AssetDiscriminator(ABC):
    """
    Responsible for discriminating (picking) assets from a release.
    """

    @abstractmethod
    def discriminate(self, release: Release) -> dict[Filename, URL]:
        raise NotImplementedError


class AllInclusiveAssetDiscriminator(AssetDiscriminator):
    """
    Default class that will, by default, take all the (valid, non-null) assets and return them.
    """
    @override
    def discriminate(self, release: Release) -> dict[Filename, URL]:
        return dict(filter(lambda s: bool(s[1]), release.assets.items()))
