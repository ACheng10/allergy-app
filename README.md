# Allergy Card (allergy-app)

An iPhone app that helps people with food allergies order food and get help abroad. You pick your allergens once, pick a country and then a language (Switzerland > French), and hand your phone to the waiter.

Plan and decisions: [product plan](https://claude.ai/code/artifact/4cb3717d-bdcb-473c-ad33-86f558db19fc).

## What is in version 1 so far

| Screen | What it does |
| --- | --- |
| Setup / Profile | Allergens, severity, country then language, emergency contact. No sign-in. Saved on the phone. |
| My Card | One giant "Show to staff" button, quick language switch, beta warning when the card is not fully reviewed. |
| Waiter Mode | Full brightness, local language large, English small underneath. Hidden-ingredient and kitchen lines picked from your allergens. |
| Ask | Fixed questions; staff tap a fixed answer in their language and you see it in English. |
| Emergency | Call buttons for the local number, your emergency contact, and phrases to show bystanders. Always free. |
| Report a problem | Profile > Report a problem. Becomes a GitHub issue that Claude diagnoses; see [docs/REPORTS_SETUP.md](docs/REPORTS_SETUP.md). |

Safety rules baked into the code:

- **No live machine translation.** The app only shows phrases from `phrasebook.json`, which is built from the CSVs in `data/`.
- **Anything not signed off by a native speaker is beta.** A line counts as reviewed only when its status is `human_reviewed`. Missing translations fall back to English and are flagged.
- **Beta warnings are shown to the user, never inside Waiter Mode.**

Right now only Cantonese has translations, and they are AI drafts waiting for a native speaker, so Cantonese is still marked beta. Every other language shows English and is marked beta. That is expected.

## Run it

New to Xcode? Follow [docs/RUNNING.md](docs/RUNNING.md). Short version: open `AllergyApp/AllergyApp.xcodeproj` in Xcode 16 or newer, pick an iPhone simulator, press Cmd+R.

## Repo layout

```
data/                       the "database": one CSV per table (see the plan's SQL schema)
  phrases_en.csv            the English source phrases
  locales.csv               fr, es, es-MX (falls back to es), ...
  countries.csv             countries and emergency numbers
  country_locales.csv       which languages each country offers, default first
  hidden_by_allergen.csv    which hidden-ingredient lines go with which allergen
  translations/<locale>.csv one file per language: text, back_translation, status, reviewer
tools/build_phrasebook.py   checks the CSVs and writes the JSON the app reads
AllergyApp/                 the Xcode project (SwiftUI + SwiftData)
reports-worker/             free Cloudflare Worker that turns in-app reports into GitHub issues
docs/                       how-tos
```

After changing anything in `data/`:

```
python3 tools/build_phrasebook.py
python3 -m unittest discover tools
```

CI fails if `phrasebook.json` is out of date with `data/`.

## Before this goes on the App Store

- [ ] Verify every emergency number in `data/countries.csv` against an official source, then set `verified` to `yes`.
- [ ] Check every `emergency.*` phrase against an official anaphylaxis action plan.
- [ ] Translations: AI draft, blind back-translation, native-speaker review (see [docs/TRANSLATIONS.md](docs/TRANSLATIONS.md)).
- [ ] Your friends with allergies check `data/hidden_by_allergen.csv` (it is a first draft).
- [ ] App icon, privacy policy, and a lawyer's look at the terms.
- [ ] Paid Apple Developer account, then turn on iCloud sync ([docs/ICLOUD_SYNC.md](docs/ICLOUD_SYNC.md)).

Learning Swift from Python? See [docs/SWIFT_FOR_PYTHON.md](docs/SWIFT_FOR_PYTHON.md).
