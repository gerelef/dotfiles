import enum
from abc import ABC, abstractmethod
from typing import Self

from modules.sela.helpers import auto_str

DESCRIPTIONS = {
    100: "This interim response indicates that the client should continue the request.",
    101: "This code is sent in response to an Upgrade request header from the client and indicates the protocol "
         "the server is switching to.",
    102: "This code indicates that the server has received and is processing the request, but no response is "
         "available yet.",
    103: "This status code is primarily intended to be used with the Link header, letting the user agent start "
         "preloading resources while the server prepares a response or preconnect to an origin from which the "
         "page will need resources.",
    200: "The request succeeded.",
    201: "The request succeeded, and a new resource was created as a result.",
    202: "The request has been received but not yet acted upon.",
    203: "This response code means the returned metadata is not exactly the same as is available from the origin "
         "server, but is collected from a local or a third-party copy.",
    204: "There is no content to send for this request, but the headers may be useful.",
    205: "Tells the user agent to reset the document which sent this request.",
    206: "This response code is used when the Range header is sent from the client to request only part of a resource.",
    207: "Conveys information about multiple resources, for situations where multiple status codes might be "
         "appropriate.",
    208: "Used inside a <dav:propstat> response element to avoid repeatedly enumerating the internal members of "
         "multiple bindings to the same collection.",
    226: "The server has fulfilled a GET request for the resource, and the response is a representation of the result "
         "of one or more instance-manipulations applied to the current instance.",
    300: "The request has more than one possible response. The user agent or user should choose one of them.",
    301: "The URL of the requested resource has been changed permanently. The new URL is given in the response.",
    302: "This response code means that the URI of requested resource has been changed temporarily. ",
    303: "The server sent this response to direct the client to get the requested resource at another URI with a GET "
         "request.",
    304: "This is used for caching purposes. It tells the client that the response has not been modified, "
         "so the client can continue to use the same cached version of the response. ",
    307: "The server sends this response to direct the client to get the requested resource at another URI with the "
         "same method that was used in the prior request. This has the same semantics as the 302 Found HTTP response "
         "code, with the exception that the user agent must not change the HTTP method used",
    308: "This means that the resource is now permanently located at another URI, specified by the Location: HTTP "
         "Response header. This has the same semantics as the 301 Moved Permanently HTTP response code, "
         "with the exception that the user agent must not change the HTTP method used",
    400: "The server cannot or will not process the request due to something that is perceived to be a client error",
    401: "Although the HTTP standard specifies \"unauthorized\", semantically this response means \"unauthenticated\".",
    403: "The client does not have access rights to the content; that is, it is unauthorized, so the server is "
         "refusing to give the requested resource.",
    404: "The server cannot find the requested resource.",
    405: "The request method is known by the server but is not supported by the target resource.",
    406: "This response is sent when the web server, after performing server-driven content negotiation, doesn't find "
         "any content that conforms to the criteria given by the user agent.",
    407: "This is similar to 401 Unauthorized but authentication is needed to be done by a proxy.",
    408: "This response is sent on an idle connection by some servers, even without any previous request by the "
         "client. It means that the server would like to shut down this unused connection. ",
    409: "This response is sent when a request conflicts with the current state of the server.",
    410: "This response is sent when the requested content has been permanently deleted from server, "
         "with no forwarding address.",
    411: "Server rejected the request because the Content-Length header field is not defined and the server requires "
         "it.",
    412: "The client has indicated preconditions in its headers which the server does not meet.",
    413: "Request entity is larger than limits defined by server. The server might close the connection or return an "
         "Retry-After header field.",
    414: "The URI requested by the client is longer than the server is willing to interpret.",
    415: "The media format of the requested data is not supported by the server, so the server is rejecting the "
         "request.",
    416: "The range specified by the Range header field in the request cannot be fulfilled. It's possible that the "
         "range is outside the size of the target URI's data.",
    417: "This response code means the expectation indicated by the Expect request header field cannot be met by the "
         "server.",
    418: "The server refuses the attempt to brew coffee with a teapot.",
    421: "The request was directed at a server that is not able to produce a response.",
    422: "The request was well-formed but was unable to be followed due to semantic errors.",
    423: "The resource that is being accessed is locked.",
    424: "The request failed due to failure of a previous request.",
    425: "Indicates that the server is unwilling to risk processing a request that might be replayed.",
    426: "The server refuses to perform the request using the current protocol but might be willing to do so after "
         "the client upgrades to a different protocol.",
    428: "The origin server requires the request to be conditional.",
    429: "The user has sent too many requests in a given amount of time.",
    431: "The server is unwilling to process the request because its header fields are too large. The request may be "
         "resubmitted after reducing the size of the request header fields.",
    451: "The user agent requested a resource that cannot legally be provided, such as a web page censored by a "
         "government.",
    500: "The server has encountered a situation it does not know how to handle.",
    501: "The request method is not supported by the server and cannot be handled.",
    502: "This error response means that the server, while working as a gateway to get a response needed to handle "
         "the request, got an invalid response.",
    503: "The server is not ready to handle the request.",
    504: "This error response is given when the server is acting as a gateway and cannot get a response in time.",
    505: "The HTTP version used in the request is not supported by the server.",
    506: "The server has an internal configuration error.",
    507: "The method could not be performed on the resource because the server is unable to store the representation "
         "needed to successfully complete the request.",
    508: "The server detected an infinite loop while processing the request.",
    510: "Further extensions to the request are required for the server to fulfill it.",
    511: "Indicates that the client needs to authenticate to gain network access."
}


class Rate(ABC):

    @abstractmethod
    def is_throttled(self) -> bool:
        raise NotImplementedError

    @abstractmethod
    def requests_remaining(self) -> int:
        raise NotImplementedError

    @abstractmethod
    def reset_time(self) -> int | None:
        """
        :returns: None if there is no reset time, int otherwise.
        """
        raise NotImplementedError


class HTTPGroup(enum.IntEnum):
    """
    HTTP Status groups.
    """
    INFORMATIONAL = 100  # starts at > 100
    SUCCESS = 200  # starts at > 200
    REDIRECTION = 300  # starts at > 300
    CLIENT_ERROR = 400  # starts at > 400
    SERVER_ERROR = 500  # starts at > 500

    @classmethod
    def create(cls, code: int) -> Self:
        """
        :param code: HTTP Status Code.
        :returns: Group Status Class. For more information:
        https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        """
        if code >= HTTPGroup.SERVER_ERROR:
            return HTTPGroup.SERVER_ERROR
        if code >= HTTPGroup.CLIENT_ERROR:
            return HTTPGroup.CLIENT_ERROR
        if code >= HTTPGroup.REDIRECTION:
            return HTTPGroup.REDIRECTION
        if code >= HTTPGroup.SUCCESS:
            return HTTPGroup.SUCCESS
        if code >= HTTPGroup.INFORMATIONAL:
            return HTTPGroup.INFORMATIONAL

    @classmethod
    def describe(cls, code: int) -> str:
        """
        :raises KeyError: raised if code is not defined in DESCRIPTIONS
        """
        if code not in DESCRIPTIONS:
            raise KeyError(code)
        return DESCRIPTIONS[code]


@auto_str
class HTTPStatus:
    def __init__(self, code: int, rate: Rate = None) -> None:
        self.__code = code
        self.__rate = rate
        self.__group = HTTPGroup.create(code)

    @property
    def code(self) -> int:
        return self.__code

    @property
    def group(self) -> HTTPGroup:
        return self.__group

    @property
    def rate(self) -> Rate | None:
        return self.__rate

    @property
    def description(self) -> str:
        return self.__group.describe(self.code)

    def is_successful(self) -> bool:
        return self.group == HTTPGroup.SUCCESS
