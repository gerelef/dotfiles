import sys
from abc import ABC, abstractmethod


class Logger(ABC):
    """
    Responsible for logging.
    Progress bar logs should be written to stdout (or stderr) directly, with sys.stdout.write and carriage return.
    """

    @abstractmethod
    def log_progress_bar(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def log_progress(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def log_info(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def log_debug(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def log_warning(self, msg: str):
        raise NotImplementedError

    @abstractmethod
    def log_err(self, msg: str):
        raise NotImplementedError


class StandardLogger(Logger):
    """
    Default class that will, by default, output logs to stdout/stderr.
    """
    def log_progress_bar(self, msg: str):
        sys.stdout.write(msg)

    def log_progress(self, msg: str):
        print(msg)

    def log_info(self, msg: str):
        print(msg)

    def log_debug(self, msg: str):
        print(msg, file=sys.stderr)

    def log_warning(self, msg: str):
        print(msg, file=sys.stderr)

    def log_err(self, msg: str):
        print(msg, file=sys.stderr)
