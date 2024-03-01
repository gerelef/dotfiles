import sys
from abc import ABC, abstractmethod
from typing import override


class Logger(ABC):
    """
    Responsible for logging.
    Progress bar logs should be written to stdout (or stderr) directly, with sys.stdout.write and carriage return.
    """

    @abstractmethod
    def progress_bar(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def progress(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def info(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def debug(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def warning(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def err(self, msg: str):
        raise NotImplementedError


class StandardLogger(Logger):
    """
    Default class that will, by default, output logs to stdout/stderr.
    """

    @override
    def progress_bar(self, msg: str):
        sys.stdout.write(msg)

    @override
    def progress(self, msg: str):
        print(msg)

    @override
    def info(self, msg: str):
        print(msg)

    @override
    def debug(self, msg: str):
        print(msg, file=sys.stderr)

    @override
    def warning(self, msg: str):
        print(msg, file=sys.stderr)

    @override
    def err(self, msg: str):
        print(msg, file=sys.stderr)


class NullLogger(Logger):
    @override
    def progress_bar(self, msg: str):
        pass

    @override
    def progress(self, msg: str):
        pass

    @override
    def info(self, msg: str):
        pass

    @override
    def debug(self, msg: str):
        pass

    @override
    def warning(self, msg: str):
        pass

    @override
    def err(self, msg: str):
        print(msg, file=sys.stderr)
