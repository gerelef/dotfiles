#!/usr/bin/env -S python3 -S -OO
import sys


if sys.version_info.minor < 12:
    print(">= python3.12 required!", file=sys.stderr)
    sys.exit(1)

if __name__ == "__main__":
    print("Hello World!")
