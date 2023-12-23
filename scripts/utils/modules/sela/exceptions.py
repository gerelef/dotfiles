from modules.sela.status import HTTPStatus


class UnknownProviderException(Exception):
    pass


class InvalidProviderURL(Exception):
    pass


class ConnectionThrottled(Exception):
    pass


class FileVerificationFailed(Exception):
    pass


class NoReleaseFound(Exception):
    pass


class NoAssetsFound(Exception):
    pass


class DependencyMissing(Exception):
    pass


class UnsuccessfulRequest(Exception):
    def __init__(self, description: str, status: HTTPStatus):
        self.status = status
        self.description = description

    def __str__(self):
        return f"Unsuccessful request with status {self.status}! {self.description}"
