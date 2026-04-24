#!/usr/bin/env python3
"""
Minimal fstab-decode replacement.

Usage:
    fstab-decode <command> [args...]

Decodes fstab-style octal escapes in all arguments, then execs the command.
Examples:
    \\040 -> space
    \\011 -> tab
    \\012 -> newline
    \\134 -> backslash
"""

import os
import re
import sys


_OCTAL_ESCAPE_RE = re.compile(r"\\([0-7]{3})")


def decode_fstab_arg(value: str) -> str:
    return _OCTAL_ESCAPE_RE.sub(
        lambda match: chr(int(match.group(1), 8)),
        value,
    )


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: fstab-decode <command> [args...]", file=sys.stderr)
        return 1

    args = [decode_fstab_arg(arg) for arg in sys.argv[1:]]

    try:
        os.execvp(args[0], args)
    except FileNotFoundError:
        print(f"fstab-decode: command not found: {args[0]}", file=sys.stderr)
        return 127
    except PermissionError:
        print(f"fstab-decode: permission denied: {args[0]}", file=sys.stderr)
        return 126


if __name__ == "__main__":
    raise SystemExit(main())
