from abc import ABC, abstractmethod

from modules.sela.releases.abstract import Release


class ReleaseDiscriminator(ABC):
    """
    Responsible for discriminating (picking) a release.
    """

    @abstractmethod
    def discriminate(self, release: Release) -> bool:
        raise NotImplementedError


class FirstReleaseDiscriminator(ReleaseDiscriminator):
    """
    Default class that will, by default, accept the first release that it gets called with.
    """
    def discriminate(self, release: Release) -> bool:
        return True
