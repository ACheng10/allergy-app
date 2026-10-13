# Allergy Card

An iOS app that helps people with food allergies eat safely abroad. The user picks a country, then a language (Switzerland > French), picks allergens and severity, and shows staff a card in the local language.

It's a personal project, released to everyone. The money goal is to cover costs plus a little side income: free card, a one-time Trip Pass or Lifetime unlock, a tip jar, no subscription, no ads. The owner has no allergy themself; friends who do are the first testers.

## Working with the owner

- They code in Python and SQL and have no Swift experience. Explain Swift through Python/SQL analogies or ELI5.
- No em dashes in anything you write.
- Be a blunt mentor: push back, point out blind spots, cite sources, ask when unsure. Don't agree just to be agreeable.
- Keep PRs small and get CI green before asking them to merge.

## Stack and commands

- SwiftUI + SwiftData, iOS 17+, Swift 5 mode, no sign-in. The Xcode project is hand-written (folder-synced, objectVersion 77), so the CI macOS build is the compile check.
- iCloud sync is off until there's a paid Apple developer account (`docs/ICLOUD_SYNC.md`). Every `@Model` property keeps a default so turning it on stays a settings change.
- Phrase data lives in CSV "tables" in `data/`. `python3 tools/build_phrasebook.py` turns them into `AllergyApp/AllergyApp/Resources/phrasebook.json`. Run it after any CSV change; CI fails if the JSON is stale (`--check`).
- Tests: `python3 -m unittest discover tools`.
- Manual screenshots: the `smoke.yml` workflow (workflow_dispatch only) uses the DEBUG launch flags in `Models/DebugFlags.swift`.

## Hard rules

- Never machine-translate safety text inside the app. Translations are drafted offline into `data/translations/<locale>.csv`.
- Only `status=human_reviewed` counts as reviewed. Everything else shows the user a beta warning. Don't mark a row reviewed without a named native reviewer.
- Missing translations fall back up the locale chain (`es-MX` > `es`), then to English.
- Emergency numbers in `data/countries.csv` are `verified=no` (written from memory). That is a release blocker.
- Emergency lines and `allergen.red_meat` (alpha-gal) need a medical reviewer in every language.

## Translations

- Drafted languages: fr, de, it, es (neutral base; the es-ES/es-MX/es-AR override files exist but are still empty), zh-Hans, zh-Hant-TW, yue-Hant, pl, pt (Portugal), pt-BR (overrides). Dutch (nl) is untranslated.
- Each draft row has a blind AI back-translation. `docs/TRANSLATION_REVIEW.md` lists the risky lines per language.
- Reviewers: there's a native reviewer for every language except Dutch. Spanish reviewer is from Spain; Portuguese reviewer is from Portugal (so pt can leave beta, pt-BR stays beta).
- Review sheets, one per language, are in the owner's Google Drive folder "Allergy Card translation review". When filled-in sheets come back, import by `phrase_id`, and first check that each sheet's draft column still matches the CSV text: the sheets were copied in by hand, so flag mismatches rather than trusting the sheet.

## Product decisions so far

- The interface is English-only in v1.
- Waiter Mode shows a short card first (allergens, severity, "includes any oil, sauce...", "check with the chef"). Specific hidden ingredients and cross-contact lines sit behind "More for the kitchen" (`CardBuilder.shortSections` / `kitchenSections`).
- "Tree nuts" was reworded to "All nuts, such as..." because the owner found "tree nut" a Western term.
- Allergens are grouped in `Models/AllergenGroups.swift`; any id not listed lands in "Other". Peanut sits under "Peanuts and legumes".
- Problem reports go app > Cloudflare Worker (`reports-worker/`) > GitHub issue > `claude-reports.yml`. It isn't set up yet (`docs/REPORTS_SETUP.md`). Make the repo private first, because reports contain health information.

## Open questions for the owner

- Should peanut also appear under Nuts?
- Should onion include spring onion?
- Japanese and Thai are bigger gaps than Polish for travellers.
- Feature ideas offered, none chosen yet: save card as image/PDF, severity per allergen, "something not listed" (English only), a medication line.
