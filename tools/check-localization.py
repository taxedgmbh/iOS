#!/usr/bin/env python3
"""Checks that the app's strings and its code agree.

Three failures this catches, all of which shipped at some point:

  * A key used in Swift with no entry in a .strings file. iOS renders the key
    itself, so the screen shows `privacy.data_storage.title` to a client.
  * A key present in one language and missing in another. Same result, but only
    for the people who chose that language — so it survives testing.
  * A key in the .strings files that nothing uses. Harmless on screen, but it
    is what let 1,250 dead keys per language accumulate behind features that no
    longer existed.

Run from the repository root:  python3 tools/check-localization.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "TaxedGmbH_IOS"
LANGUAGES = ["en", "de", "fr", "it"]

# "some.key".localized  and  "some.key".localized(with: …)
LITERAL_KEY = re.compile(r'"([A-Za-z][A-Za-z0-9_.]*)"\s*\.localized')
# DriveCategory builds "category.<folder>" at runtime from server data, so the
# keys are never literals in the source.
DYNAMIC_PREFIXES = ("category.",)

ENTRY = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')


def keys_used_in_code() -> set[str]:
    keys: set[str] = set()
    for path in APP.rglob("*.swift"):
        keys |= set(LITERAL_KEY.findall(path.read_text(encoding="utf-8")))
    return keys


def keys_in_strings(language: str) -> dict[str, str]:
    path = APP / f"{language}.lproj" / "Localizable.strings"
    entries: dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = ENTRY.match(line)
        if match:
            key = match.group(1)
            if key in entries:
                print(f"{path.name}:{number}: duplicate key {key}")
            entries[key] = match.group(2)
    return entries


def main() -> int:
    problems = 0
    used = keys_used_in_code()
    catalogues = {language: keys_in_strings(language) for language in LANGUAGES}
    base = set(catalogues["en"])

    for language in LANGUAGES:
        present = set(catalogues[language])

        for key in sorted(used - present):
            print(f"{language}: used in code, missing from strings — {key}")
            problems += 1

        for key in sorted(base - present):
            print(f"{language}: in English, missing here — {key}")
            problems += 1

        for key in sorted(present - base):
            print(f"{language}: present here, missing from English — {key}")
            problems += 1

        unused = {
            key for key in present - used
            if not key.startswith(DYNAMIC_PREFIXES)
        }
        for key in sorted(unused):
            print(f"{language}: in strings, used nowhere — {key}")
            problems += 1

        # A format specifier count that differs between languages crashes at
        # runtime rather than looking wrong.
        for key, value in catalogues[language].items():
            english = catalogues["en"].get(key)
            if english is None:
                continue
            if value.count("%") != english.count("%"):
                print(f"{language}: format specifiers differ from English — {key}")
                problems += 1

    if problems:
        print(f"\n{problems} problem(s).")
        return 1

    print(f"OK — {len(base)} keys across {len(LANGUAGES)} languages.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
