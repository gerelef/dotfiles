from abc import ABC, abstractmethod
from typing import override, Callable

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


class KeywordReleaseDiscriminator(ReleaseDiscriminator):
    """
    Default class that will, by default, accept the first release that contains any of the matched text(s).
    """

    def __init__(self, *kws, preprocess: Callable[[str], str] = lambda s: s, strict=False):
        """
        @param preprocess: Preprocessor before each check.
        """
        self.kws = kws
        self.prep = preprocess
        self.strict = strict

    @override
    def discriminate(self, release: Release) -> bool:
        check = all if self.strict else any
        return check([keyword in self.prep(release.name_human_readable) for keyword in self.kws])


class LambdaReleaseDiscriminator(ReleaseDiscriminator):
    """
    Default class that will, by default, accept the first release that fulfills all lambdas' requirements.
    """

    def __init__(self, *lds: Callable[[Release], bool], strict=False):
        self.lambdas = lds
        self.strict = strict

    @override
    def discriminate(self, release: Release) -> bool:
        check = all if self.strict else any
        return check([evaluator(release) for evaluator in self.lambdas])
