"""Turn the CSV files in data/ into the one JSON file the iOS app reads.

Think of data/ as a tiny SQL database (one CSV per table) and this script as
the export job: it checks the foreign keys, then writes
AllergyApp/AllergyApp/Resources/phrasebook.json. The app never talks to a
server; it only reads that file.

Run from the repo root:
    python3 tools/build_phrasebook.py          # build
    python3 tools/build_phrasebook.py --check  # fail if the JSON is out of date
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
OUTPUT = ROOT / "AllergyApp" / "AllergyApp" / "Resources" / "phrasebook.json"

# Same states as the plan's phrase_translation.status column.
STATUSES = ("ai_draft", "ai_checked", "human_reviewed")
SOURCE_LOCALE = "en"


class DataError(Exception):
    pass


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as f:
        return [{k: (v or "").strip() for k, v in row.items()} for row in csv.DictReader(f)]


def build(data_dir: Path = DATA) -> dict:
    errors: list[str] = []

    phrases = read_csv(data_dir / "phrases_en.csv")
    phrase_ids = [p["id"] for p in phrases]
    dupes = sorted({i for i in phrase_ids if phrase_ids.count(i) > 1})
    if dupes:
        errors.append(f"duplicate phrase ids: {dupes}")
    known_phrases = set(phrase_ids)

    locales = read_csv(data_dir / "locales.csv")
    locale_codes = {l["code"] for l in locales}
    for l in locales:
        if l["parent_code"] and l["parent_code"] not in locale_codes:
            errors.append(f"locale {l['code']}: unknown parent {l['parent_code']}")

    countries = read_csv(data_dir / "countries.csv")
    country_codes = {c["code"] for c in countries}

    links = read_csv(data_dir / "country_locales.csv")
    locales_by_country: dict[str, list[tuple[int, str]]] = {c: [] for c in country_codes}
    for link in links:
        if link["country_code"] not in country_codes:
            errors.append(f"country_locales: unknown country {link['country_code']}")
            continue
        if link["locale_code"] not in locale_codes:
            errors.append(f"country_locales: unknown locale {link['locale_code']}")
            continue
        locales_by_country[link["country_code"]].append((int(link["sort_order"]), link["locale_code"]))
    for code, items in locales_by_country.items():
        if not items:
            errors.append(f"country {code} has no languages")

    hidden: dict[str, list[str]] = {}
    for row in read_csv(data_dir / "hidden_by_allergen.csv"):
        for col in ("allergen_id", "hidden_id"):
            if row[col] not in known_phrases:
                errors.append(f"hidden_by_allergen: unknown phrase {row[col]}")
        hidden.setdefault(row["allergen_id"], []).append(row["hidden_id"])

    translations: dict[str, dict[str, dict[str, str]]] = {}
    for path in sorted((data_dir / "translations").glob("*.csv")):
        locale = path.stem
        if locale not in locale_codes:
            errors.append(f"{path.name}: no such locale in locales.csv")
            continue
        rows: dict[str, dict[str, str]] = {}
        for n, row in enumerate(read_csv(path), start=2):
            where = f"{path.name} line {n}"
            if row["phrase_id"] not in known_phrases:
                errors.append(f"{where}: unknown phrase {row['phrase_id']}")
            if row["status"] not in STATUSES:
                errors.append(f"{where}: status must be one of {STATUSES}, got {row['status']!r}")
            if not row["text"]:
                errors.append(f"{where}: empty text")
            if row["phrase_id"] in rows:
                errors.append(f"{where}: {row['phrase_id']} appears twice")
            rows[row["phrase_id"]] = {"text": row["text"], "status": row["status"]}
        translations[locale] = rows

    if errors:
        raise DataError("\n".join(errors))

    return {
        "sourceLocale": SOURCE_LOCALE,
        "phrases": [
            {"id": p["id"], "category": p["category"], "english": p["english"]} for p in phrases
        ],
        "locales": [
            {
                "code": l["code"],
                "parent": l["parent_code"] or None,
                "name": l["name"],
                "nativeName": l["native_name"],
            }
            for l in locales
        ],
        "countries": [
            {
                "code": c["code"],
                "name": c["name"],
                "emergencyNumber": c["emergency_number"],
                "ambulanceNumber": c["ambulance_number"],
                "emergencyNote": c["emergency_note"],
                "numbersVerified": c["verified"] == "yes",
                "locales": [code for _, code in sorted(locales_by_country[c["code"]])],
            }
            for c in countries
        ],
        "hiddenByAllergen": hidden,
        "translations": translations,
    }


def render(book: dict) -> str:
    return json.dumps(book, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="exit 1 if phrasebook.json is stale")
    args = parser.parse_args()

    try:
        text = render(build())
    except DataError as e:
        print(f"Data problems:\n{e}", file=sys.stderr)
        return 1

    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != text:
            print("phrasebook.json is out of date; run python3 tools/build_phrasebook.py", file=sys.stderr)
            return 1
        print("phrasebook.json is up to date")
        return 0

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(text, encoding="utf-8")
    book = json.loads(text)
    done = sum(len(v) for v in book["translations"].values())
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: {len(book['phrases'])} phrases, "
          f"{len(book['countries'])} countries, {done} translated rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
