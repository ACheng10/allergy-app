"""Run with: python3 -m unittest discover tools"""

import shutil
import tempfile
import unittest
from pathlib import Path

import build_phrasebook as bp


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(bp.DATA, self.tmp / "data")
        self.data = self.tmp / "data"

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def write_translation(self, locale, *rows):
        lines = ["phrase_id,text,back_translation,status,reviewer", *rows]
        (self.data / "translations" / f"{locale}.csv").write_text("\n".join(lines) + "\n", encoding="utf-8")

    def test_real_data_builds(self):
        book = bp.build(self.data)
        self.assertGreater(len(book["phrases"]), 100)
        ch = next(c for c in book["countries"] if c["code"] == "CH")
        self.assertEqual(ch["locales"], ["de", "fr", "it"])

    def test_translation_is_kept_with_status(self):
        self.write_translation("fr", "intro.hello,Bonjour.,Hello.,ai_draft,")
        book = bp.build(self.data)
        self.assertEqual(book["translations"]["fr"]["intro.hello"], {"text": "Bonjour.", "status": "ai_draft"})

    def test_rejects_unknown_status(self):
        self.write_translation("fr", "intro.hello,Bonjour.,,approved,")
        with self.assertRaisesRegex(bp.DataError, "status must be one of"):
            bp.build(self.data)

    def test_rejects_unknown_phrase(self):
        self.write_translation("fr", "intro.typo,Bonjour.,,ai_draft,")
        with self.assertRaisesRegex(bp.DataError, "unknown phrase intro.typo"):
            bp.build(self.data)

    def test_rejects_file_for_unknown_locale(self):
        self.write_translation("pt", "intro.hello,Olá.,,ai_draft,")
        with self.assertRaisesRegex(bp.DataError, "no such locale"):
            bp.build(self.data)

    def test_committed_json_is_current(self):
        self.assertEqual(bp.OUTPUT.read_text(encoding="utf-8"), bp.render(bp.build()))


if __name__ == "__main__":
    unittest.main()
