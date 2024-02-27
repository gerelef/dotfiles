from abc import ABC, abstractmethod
from typing import override, Callable

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


class KeywordAssetDiscriminator(AssetDiscriminator):
    """
    Default class that will, by default, take all the assets that match all keywords and return them.
    """

    def __init__(self, *kws: str, preprocess: Callable[[str], str] = lambda s: s, strict=False):
        """
        @param preprocess: Preprocessor before each check.
        """
        self.kws = kws
        self.prep = preprocess
        self.strict = strict

    @override
    def discriminate(self, release: Release) -> dict[Filename, URL]:
        check = all if self.strict else any
        td = {}
        for fn, url in release.assets.items():
            evaluations = [keyword in self.prep(fn) for keyword in self.kws]
            if check(evaluations):
                td[fn] = url
        return td


class LambdaAssetDiscriminator(AssetDiscriminator):
    """
    Default class that will, by default, take all the assets that match at least one lambda and return them.
    """

    def __init__(self, *lds: Callable[[str, str], bool], strict=False):
        self.lambdas = lds
        self.strict = strict

    @override
    def discriminate(self, release: Release) -> dict[Filename, URL]:
        check = all if self.strict else any
        td = {}
        for fn, url in release.assets.items():
            evaluations = [evaluator(fn, url) for evaluator in self.lambdas]
            if check(evaluations):
                td[fn] = url
        return td
