from abc import ABC, abstractmethod
from typing import override

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

    @override
    def discriminate(self, release: Release) -> bool:
        return True


class SimpleMatchDiscriminator(ReleaseDiscriminator):
    """
    Default class that will, by default, accept the first release that contains the matched text.
    """

    def __init__(self, match):
        self.match = match

    @override
    def discriminate(self, release: Release) -> bool:
        return self.match in release.name_human_readable
