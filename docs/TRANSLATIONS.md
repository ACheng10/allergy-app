# Adding translations

Each language has one file in `data/translations/`, named by locale code (`fr.csv`, `es-MX.csv`). Columns:

| Column | Meaning |
| --- | --- |
| `phrase_id` | must exist in `data/phrases_en.csv` |
| `text` | the translation shown to staff |
| `back_translation` | a separate, blind AI translation back to English, for checking |
| `status` | `ai_draft`, `ai_checked` or `human_reviewed` |
| `reviewer` | who signed it off (credit them in the app later) |

Rules the app enforces:

- Only `human_reviewed` counts as reviewed. Everything else shows the user a "beta" warning.
- A phrase with no row falls back up the locale chain (`es-MX` to `es`), then to English, and is flagged as missing.
- Country files like `es-MX.csv` only need the phrases that differ from `es.csv` (mostly food words, e.g. peanut).
- Dutch and every Spanish variant except `es-ES` stay beta until a native reviewer from that country checks them. The same goes for `pt-BR`.
- `docs/TRANSLATION_REVIEW.md` lists the rows the AI back-translation check flagged, per language. Reviewers should start there.

The build script rejects unknown phrase ids, unknown statuses, empty text and duplicate rows, so a typo fails loudly instead of shipping.

The AI drafting pipeline from the plan (glossary, translate, blind back-translate, flag mismatches) is not built yet. It belongs in `tools/` as a Python script that writes these CSVs. It must never run inside the app.
