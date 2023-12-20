class UnknownProviderException(Exception):
    pass


class FileVerificationFailed(Exception):
    pass


class NoReleaseFound(Exception):
    pass


class NoAssetsFound(Exception):
    pass


class DependencyMissing(Exception):
    pass
