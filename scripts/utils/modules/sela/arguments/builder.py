import argparse as ap
from typing import Self


# TODO add compgen generator from ArgumentParser
class ArgumentParserBuilder:
    # FIXME add documentation
    DEFAULT_VERSION: tuple[(str, ...), dict[...]] = (
        ("-v", "--version"),
        {
            "help": "Specify a version to install.",
            "required": False,
            "default": None
        }
    )

    DEFAULT_KEEP: tuple[(str, ...), dict[...]] = (
        ("-k", "--keep"),
        {
            "help": "Specify if temporary file cleanup will be performed.",
            "required": False,
            "default": False,
            "action": "store_true"
        }
    )

    DEFAULT_TEMPORARY: tuple[(str, ...), dict[...]] = (
        ("-t", "--temporary"),
        {
            "help": "Specify temporary (download) directory files.",
            "required": False,
            "default": None,
            "type": str
        }
    )

    DEFAULT_DESTINATION: tuple[(str, ...), dict[...]] = (
        ("-d", "--destination"),
        {
            "help": "Specify installation directory.",
            "required": False,
            "default": None,
            "type": str
        }
    )

    DEFAULT_UNSAFE: tuple[(str, ...), dict[...]] = (
        ("-u", "--unsafe"),
        {
            "help": "Specify if file verification will be skipped.",
            "required": False,
            "default": False,
            "action": "store_true"
        }
    )

    def __init__(self, description: str):
        self.parser = ap.ArgumentParser(description=description)

    def add_version(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_VERSION
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_keep(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_KEEP
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_temporary(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_TEMPORARY
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_destination(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_DESTINATION
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_unsafe(self) -> Self:
        flags, kwargs = ArgumentParserBuilder.DEFAULT_UNSAFE
        self.parser.add_argument(*flags, **kwargs)
        return self

    def add_arguments(self, flags_kwargs_dict: dict[..., dict[...]]) -> Self:
        for flags, argopts in flags_kwargs_dict.items():
            self.parser.add_argument(*flags, **argopts)
        return self

    def add_mutually_exclusive_group(self, flags_kwargs_dict: dict[..., dict[...]], required=True) -> Self:
        meg = self.parser.add_mutually_exclusive_group(required=required)
        for flags, argopts in flags_kwargs_dict.items():
            meg.add_argument(*flags, **argopts)
        return self

    def build(self) -> ap.ArgumentParser:
        return self.parser
