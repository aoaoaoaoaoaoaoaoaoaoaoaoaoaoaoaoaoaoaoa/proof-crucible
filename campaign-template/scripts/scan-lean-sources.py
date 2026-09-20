#!/usr/bin/env python3
"""Reject proof apertures in Lean code while ignoring comments and strings."""

from __future__ import annotations

import re
import sys
from pathlib import Path


PROHIBITED = re.compile(
    r"\b(?:sorry|admit|axiom|native_decide|unsafe|partial|implemented_by|run_tac|"
    r"run_cmd|sorryAx|ofReduceBool|extern)\b|@\s*\[\s*nolint\b"
)
RELAXATION = re.compile(
    r"\bset_option\s+(?:autoImplicit\s+true|warningAsError\s+false|"
    r"linter\.[^\s]+\s+false|debug\.skipKernelTC\s+true)\b"
)


def code_only(source: str) -> str:
    output: list[str] = []
    index = 0
    block_depth = 0
    string = False
    while index < len(source):
        pair = source[index : index + 2]
        character = source[index]
        if block_depth:
            if pair == "/-":
                block_depth += 1
                output.extend("  ")
                index += 2
            elif pair == "-/":
                block_depth -= 1
                output.extend("  ")
                index += 2
            else:
                output.append("\n" if character == "\n" else " ")
                index += 1
        elif string:
            if character == "\\" and index + 1 < len(source):
                output.extend("  ")
                index += 2
            elif character == '"':
                string = False
                output.append(" ")
                index += 1
            else:
                output.append("\n" if character == "\n" else " ")
                index += 1
        elif pair == "/-":
            block_depth = 1
            output.extend("  ")
            index += 2
        elif pair == "--":
            end = source.find("\n", index)
            if end == -1:
                output.extend(" " * (len(source) - index))
                break
            output.extend(" " * (end - index))
            index = end
        elif character == '"':
            string = True
            output.append(" ")
            index += 1
        else:
            output.append(character)
            index += 1
    if block_depth:
        raise ValueError("unterminated block comment")
    if string:
        raise ValueError("unterminated string")
    return "".join(output)


def line_number(source: str, offset: int) -> int:
    return source.count("\n", 0, offset) + 1


def main(arguments: list[str]) -> int:
    if not arguments:
        print("no proof sources supplied", file=sys.stderr)
        return 1
    for argument in arguments:
        path = Path(argument)
        if not path.is_file():
            print(f"missing proof source: {path}", file=sys.stderr)
            return 1
        try:
            source = path.read_text(encoding="utf-8")
            code = code_only(source)
        except (UnicodeDecodeError, ValueError) as error:
            print(f"unreadable Lean source {path}: {error}", file=sys.stderr)
            return 1
        for pattern, message in (
            (PROHIBITED, "forbidden proof aperture"),
            (RELAXATION, "forbidden strictness relaxation"),
        ):
            match = pattern.search(code)
            if match:
                line = line_number(code, match.start())
                print(f"{path}:{line}: {message}: {match.group(0)}", file=sys.stderr)
                return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
