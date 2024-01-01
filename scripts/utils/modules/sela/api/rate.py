from typing import final

from modules.sela.status import Rate


@final
class GitHubRate(Rate):
    def __init__(self, total_limit: int, remaining_limit: int, limit_reset: int):
        """
        :param total_limit:
        :param remaining_limit:
        :param limit_reset: unix time in seconds after which the rate is reset
        """
        self.rate_limit: int = total_limit
        self.rate_limit_remaining: int = remaining_limit
        self.rate_limit_reset: int = limit_reset

    def is_throttled(self) -> bool:
        return self.rate_limit_remaining == 0

    def requests_remaining(self) -> int:
        return self.rate_limit_remaining

    def reset_time(self) -> int | None:
        return self.rate_limit_reset
