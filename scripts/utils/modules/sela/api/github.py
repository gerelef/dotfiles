import sys

from requests import Response

from modules.sela.api.rate import GitHubRate
from modules.sela.definitions import URL
from modules.sela.status import Rate, HTTPStatus
from modules.sela.exceptions import ConnectionThrottled

RATE_LIMIT_LIMIT_KEY = "X-RateLimit-Limit"
RATE_LIMIT_REMAINING_KEY = "X-RateLimit-Remaining"
RATE_LIMIT_RESET_KEY = "X-RateLimit-Reset"
GITHUB_API_VERSION_KEY = "X-GitHub-Api-Version"
AUTHORIZATION_KEY = "Authorization"


def get_request(url: URL, auth_token=None, *args, **kwargs) -> tuple[HTTPStatus, Response | None]:
    """
    :raises ConnectionThrottled: raised if the response is 403 or 429 and x-ratelimit-remaining 0
    """
    try:
        import requests
    except NameError:
        print(
            "FATAL! Couldn't find requests library! Is it installed in the current environment?",
            file=sys.stderr
        )
        exit(1)

    headers = {GITHUB_API_VERSION_KEY: "2022-11-28"}
    if auth_token:
        headers |= {AUTHORIZATION_KEY: f"Bearer {auth_token}"}

    response = requests.get(
        url,
        verify=True,
        allow_redirects=True,
        headers=headers,
        *args,
        **kwargs
    )

    rate = GitHubRate(
        total_limit=int(response.headers[RATE_LIMIT_LIMIT_KEY]) if RATE_LIMIT_LIMIT_KEY in response.headers else None,
        remaining_limit=int(response.headers[RATE_LIMIT_REMAINING_KEY]) if RATE_LIMIT_REMAINING_KEY in response.headers else None,
        limit_reset=int(response.headers[RATE_LIMIT_RESET_KEY]) if RATE_LIMIT_RESET_KEY in response.headers else None
    )

    status = HTTPStatus(response.status_code, rate=rate)
    if not status.is_successful() and (status.code == 403 or status.code == 429) and rate.is_throttled():
        raise ConnectionThrottled(status)

    return status, response
