from typing import final, Optional

from modules.sela.status import Rate


@final
class GitHubRate(Rate):
    def __init__(self, total_limit: Optional[int], remaining_limit: Optional[int], limit_reset: Optional[int]):
        """
        :param total_limit:
        :param remaining_limit:
        :param limit_reset: unix time in seconds after which the rate is reset
        """
        self.rate_limit: Optional[int] = total_limit
        self.rate_limit_remaining: Optional[int] = remaining_limit
        self.rate_limit_reset: Optional[int] = limit_reset

    def is_throttled(self) -> bool | None:
        if self.rate_limit_remaining is None:
            return None

        return self.rate_limit_remaining == 0

    def requests_remaining(self) -> int | None:
        return self.rate_limit_remaining

    def reset_time(self) -> int | None:
        return self.rate_limit_reset
