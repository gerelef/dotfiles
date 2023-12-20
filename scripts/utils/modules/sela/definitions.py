import enum
from typing import Self

type Filename = str
type URL = str


class HTTPStatus(enum.IntEnum):
    """
    Group HTTP Status classes.
    """
    INFORMATIONAL = 99  # starts at > 100
    SUCCESS = 199  # starts at > 200
    REDIRECTION = 299  # starts at > 300
    CLIENT_ERROR = 399  # starts at > 400
    SERVER_ERROR = 499  # starts at > 500

    @classmethod
    def create(cls, code: int) -> Self:
        """
        :param code: HTTP Status Code.
        :returns: Group Status Class. For more information:
        https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        """
        if code > HTTPStatus.SERVER_ERROR:
            return HTTPStatus.SERVER_ERROR
        if code > HTTPStatus.CLIENT_ERROR:
            return HTTPStatus.CLIENT_ERROR
        if code > HTTPStatus.REDIRECTION:
            return HTTPStatus.REDIRECTION
        if code > HTTPStatus.SUCCESS:
            return HTTPStatus.SUCCESS
        if code > HTTPStatus.INFORMATIONAL:
            return HTTPStatus.INFORMATIONAL
