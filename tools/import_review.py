"""Import a filled-in reviewer sheet into data/translations/<locale>.csv.

Export the Google Sheet as CSV (File > Download > CSV), then run from the repo root:
    python3 tools/import_review.py --locale fr --reviewer "Marie Dupont" review-fr.csv          # dry run
    python3 tools/import_review.py --locale fr --reviewer "Marie Dupont" review-fr.csv --write  # apply

Think of it as an UPDATE ... JOIN on phrase_id, with a safety check first: the
sheets were copied by hand, so a row is only imported if the sheet's draft
column still matches the CSV text. Anything else is listed, never guessed.

Per row, by the reviewer's verdict:
    OK            -> status human_reviewed, reviewer set
    Fix + text    -> text replaced, back_translation cleared (it is stale),
                     status human_reviewed, reviewer set
    blank         -> left alone (not reviewed yet)
    anything else -> listed as a problem, left alone

Emergency lines and allergen.red_meat need a medical reviewer as well, so they
are never marked human_reviewed here. A Fix is still applied to their text, but
the status stays as it was and the row is listed.

After --write, run python3 tools/build_phrasebook.py.
"""

from __future__ import annotations

import argparse
import csv
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

import build_phrasebook as bp

FIELDS = ["phrase_id", "text", "back_translation", "status", "reviewer"]


def needs_medical_review(phrase_id: str) -> bool:
    return phrase_id.startswith("emergency.") or phrase_id == "allergen.red_meat"


def norm(text: str) -> str:
    # Same text typed or pasted twice can differ in invisible ways (NFC vs NFD
    # accents, non-breaking spaces, doubled spaces). Those are not real edits.
    return " ".join(unicodedata.normalize("NFC", text).replace(" ", " ").split())


@dataclass
class Report:
    approved: list[str] = field(default_factory=list)
    fixed: list[str] = field(default_factory=list)
    medical: list[str] = field(default_factory=list)
    unreviewed: list[str] = field(default_factory=list)
    problems: list[str] = field(default_factory=list)

    def lines(self) -> list[str]:
        out = [
            f"approved (OK):        {len(self.approved)}",
            f"fixed (new text):     {len(self.fixed)}",
            f"not reviewed (blank): {len(self.unreviewed)}",
        ]
        if self.fixed:
            out.append("fixed rows have no back-translation now; re-run the blind check on: " + ", ".join(self.fixed))
        if self.medical:
            out.append("left unreviewed, need a medical reviewer too: " + ", ".join(self.medical))
        if self.problems:
            out.append(f"PROBLEMS ({len(self.problems)}), these rows were not imported:")
            out += [f"  - {p}" for p in self.problems]
        return out


def find_column(header: list[str], want: str) -> str:
    """Sheet headers are human text ('Your verdict (OK / Fix)'); match on a key word."""
    matches = [h for h in header if want in h.lower()]
    if len(matches) != 1:
        raise bp.DataError(f"sheet needs exactly one column containing {want!r}, found {matches}")
    return matches[0]


def read_sheet(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        header = reader.fieldnames or []
        cols = {key: find_column(header, key) for key in ("phrase_id", "draft", "verdict", "correction")}
        return [{key: (row.get(col) or "").strip() for key, col in cols.items()} for row in reader]


def apply_review(rows: list[dict[str, str]], sheet: list[dict[str, str]], reviewer: str,
                 known_phrases: set[str]) -> Report:
    report = Report()
    by_id = {r["phrase_id"]: r for r in rows}
    seen: set[str] = set()
    for s in sheet:
        pid = s["phrase_id"]
        if not pid:
            continue
        if pid in seen:
            report.problems.append(f"{pid}: appears twice in the sheet")
            continue
        seen.add(pid)
        if pid not in known_phrases:
            report.problems.append(f"{pid}: unknown phrase id")
            continue
        row = by_id.get(pid)
        if row is None:
            report.problems.append(f"{pid}: no row in this locale's CSV")
            continue
        if norm(s["draft"]) != norm(row["text"]):
            report.problems.append(f"{pid}: sheet draft does not match CSV\n      sheet: {s['draft']}\n      csv:   {row['text']}")
            continue

        verdict = s["verdict"].lower()
        if not verdict:
            report.unreviewed.append(pid)
            continue
        if verdict == "fix":
            if not s["correction"]:
                report.problems.append(f"{pid}: verdict Fix but no correction")
                continue
            row["text"] = s["correction"]
            row["back_translation"] = ""
            report.fixed.append(pid)
        elif verdict == "ok":
            if s["correction"]:
                report.problems.append(f"{pid}: verdict OK but a correction was given; ask the reviewer which they meant")
                continue
            report.approved.append(pid)
        else:
            report.problems.append(f"{pid}: verdict {s['verdict']!r} is not OK or Fix")
            continue

        if needs_medical_review(pid):
            report.medical.append(pid)
        else:
            row["status"] = "human_reviewed"
            row["reviewer"] = reviewer
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sheet", type=Path, help="the reviewer sheet, exported as CSV")
    ap.add_argument("--locale", required=True, help="e.g. fr, es, pt (the file in data/translations/)")
    ap.add_argument("--reviewer", required=True, help="the native reviewer's name, as it should be credited")
    ap.add_argument("--write", action="store_true", help="apply the changes (default is a dry run)")
    args = ap.parse_args()

    reviewer = args.reviewer.strip()
    if not reviewer:
        print("--reviewer must be a real name", file=sys.stderr)
        return 1
    target = bp.DATA / "translations" / f"{args.locale}.csv"
    if not target.exists():
        print(f"no such file: {target}", file=sys.stderr)
        return 1

    rows = bp.read_csv(target)
    known = {p["id"] for p in bp.read_csv(bp.DATA / "phrases_en.csv")}
    try:
        report = apply_review(rows, read_sheet(args.sheet), reviewer, known)
    except bp.DataError as e:
        print(e, file=sys.stderr)
        return 1
    print("\n".join(report.lines()))

    if args.write:
        with target.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=FIELDS, lineterminator="\n")
            w.writeheader()
            w.writerows(rows)
        print(f"wrote {target}; now run python3 tools/build_phrasebook.py")
    else:
        print("dry run, nothing written (add --write to apply)")
    return 1 if report.problems else 0


if __name__ == "__main__":
    sys.exit(main())
