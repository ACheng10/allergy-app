"""Run with: python3 -m unittest discover tools"""

import csv
import shutil
import tempfile
import unittest
from pathlib import Path

import build_phrasebook as bp
import import_review as ir

HEADER = ["Check first?", "Category", "English (what it must mean)", "French draft",
          "AI back-translation into English", "Your verdict (OK / Fix)",
          "Your correction (only if Fix)", "Comments", "phrase_id (do not edit)"]
KNOWN = {"intro.hello", "intro.severe", "emergency.thigh", "allergen.red_meat"}


def csv_rows():
    return [
        {"phrase_id": "intro.hello", "text": "Bonjour.", "back_translation": "Hello.", "status": "ai_draft", "reviewer": ""},
        {"phrase_id": "intro.severe", "text": "Allergie grave.", "back_translation": "Severe allergy.", "status": "ai_draft", "reviewer": ""},
        {"phrase_id": "emergency.thigh", "text": "Cuisse.", "back_translation": "Thigh.", "status": "ai_draft", "reviewer": ""},
        {"phrase_id": "allergen.red_meat", "text": "Viande rouge.", "back_translation": "Red meat.", "status": "ai_draft", "reviewer": ""},
    ]


def sheet(pid, draft, verdict="", correction=""):
    return {"phrase_id": pid, "draft": draft, "verdict": verdict, "correction": correction}


class ApplyReviewTests(unittest.TestCase):
    def run_review(self, *sheet_rows):
        rows = csv_rows()
        report = ir.apply_review(rows, list(sheet_rows), "Marie", KNOWN)
        return {r["phrase_id"]: r for r in rows}, report

    def test_ok_marks_reviewed_with_name(self):
        rows, report = self.run_review(sheet("intro.hello", "Bonjour.", "OK"))
        self.assertEqual(rows["intro.hello"]["status"], "human_reviewed")
        self.assertEqual(rows["intro.hello"]["reviewer"], "Marie")
        self.assertEqual(report.approved, ["intro.hello"])

    def test_fix_replaces_text_and_clears_back_translation(self):
        rows, report = self.run_review(sheet("intro.hello", "Bonjour.", "Fix", "Bonjour !"))
        self.assertEqual(rows["intro.hello"]["text"], "Bonjour !")
        self.assertEqual(rows["intro.hello"]["back_translation"], "")
        self.assertEqual(rows["intro.hello"]["status"], "human_reviewed")

    def test_draft_mismatch_is_refused(self):
        rows, report = self.run_review(sheet("intro.hello", "Bonjour", "OK"))
        self.assertEqual(rows["intro.hello"]["status"], "ai_draft")
        self.assertIn("does not match", report.problems[0])

    def test_invisible_differences_still_match(self):
        rows, _ = self.run_review(sheet("intro.severe", "Allergie  grave. ", "ok"))
        self.assertEqual(rows["intro.severe"]["status"], "human_reviewed")

    def test_blank_verdict_is_left_alone(self):
        rows, report = self.run_review(sheet("intro.hello", "Bonjour."))
        self.assertEqual(rows["intro.hello"]["status"], "ai_draft")
        self.assertEqual(report.unreviewed, ["intro.hello"])

    def test_medical_lines_are_never_marked_reviewed(self):
        rows, report = self.run_review(sheet("emergency.thigh", "Cuisse.", "OK"),
                                       sheet("allergen.red_meat", "Viande rouge.", "Fix", "Viande de mammifère."))
        self.assertEqual(rows["emergency.thigh"]["status"], "ai_draft")
        self.assertEqual(rows["allergen.red_meat"]["status"], "ai_draft")
        self.assertEqual(rows["allergen.red_meat"]["text"], "Viande de mammifère.")
        self.assertEqual(report.medical, ["emergency.thigh", "allergen.red_meat"])

    def test_bad_rows_are_problems(self):
        rows, report = self.run_review(
            sheet("intro.hello", "Bonjour.", "Fix"),
            sheet("intro.severe", "Allergie grave.", "maybe"),
            sheet("intro.typo", "x", "OK"),
            sheet("intro.severe", "Allergie grave.", "OK"),
        )
        self.assertEqual(len(report.problems), 4)
        self.assertTrue(all(r["status"] == "ai_draft" for r in rows.values()))

    def test_ok_with_correction_is_ambiguous(self):
        rows, report = self.run_review(sheet("intro.hello", "Bonjour.", "OK", "Salut."))
        self.assertEqual(rows["intro.hello"]["text"], "Bonjour.")
        self.assertEqual(len(report.problems), 1)


class ReadSheetTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_reads_the_drive_sheet_layout(self):
        path = self.tmp / "sheet.csv"
        with path.open("w", newline="", encoding="utf-8-sig") as f:
            w = csv.writer(f)
            w.writerow(HEADER)
            w.writerow(["", "intro", "Hello.", "Bonjour.", "Hello.", "OK", "", "", "intro.hello"])
        self.assertEqual(ir.read_sheet(path), [sheet("intro.hello", "Bonjour.", "OK")])

    def test_missing_column_fails_loudly(self):
        path = self.tmp / "sheet.csv"
        path.write_text("phrase_id,French draft\nintro.hello,Bonjour.\n", encoding="utf-8")
        with self.assertRaisesRegex(bp.DataError, "verdict"):
            ir.read_sheet(path)


if __name__ == "__main__":
    unittest.main()
