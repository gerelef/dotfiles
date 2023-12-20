from abc import ABC, abstractmethod

from modules.sela.sela.definitions import URL
from modules.sela.providers import Provider


class ProviderFactory(ABC):
    """
    Supported Git provider abstract factory.
    """

    def __init__(self, url: URL):
        self.repository = url

    @abstractmethod
    def create(self) -> Provider:
        raise NotImplementedError
