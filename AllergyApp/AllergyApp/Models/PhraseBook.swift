import Foundation

/// Everything in phrasebook.json, the file tools/build_phrasebook.py writes.
/// Python analogy: these structs are dataclasses, and `Decodable` is the
/// `json.load` + constructor step done for you.
struct PhraseBook: Decodable, Sendable {
    let sourceLocale: String
    let phrases: [Phrase]
    let locales: [PhraseLocale]
    let countries: [Country]
    let hiddenByAllergen: [String: [String]]
    /// locale code -> phrase id -> translation
    let translations: [String: [String: Translation]]

    struct Phrase: Decodable, Identifiable, Hashable, Sendable {
        let id: String
        let category: String
        let english: String
    }

    struct PhraseLocale: Decodable, Identifiable, Hashable, Sendable {
        let code: String
        let parent: String?
        let name: String
        let nativeName: String
        var id: String { code }
    }

    struct Country: Decodable, Identifiable, Hashable, Sendable {
        let code: String
        let name: String
        let emergencyNumber: String
        let ambulanceNumber: String
        let emergencyNote: String
        let numbersVerified: Bool
        let locales: [String]
        var id: String { code }
    }

    struct Translation: Decodable, Hashable, Sendable {
        let text: String
        let status: ReviewStatus
    }

    enum ReviewStatus: String, Decodable, Sendable {
        case aiDraft = "ai_draft"
        case aiChecked = "ai_checked"
        case humanReviewed = "human_reviewed"
    }

    static func loadBundled() -> PhraseBook {
        guard let url = Bundle.main.url(forResource: "phrasebook", withExtension: "json") else {
            fatalError("phrasebook.json is missing from the app bundle. Run python3 tools/build_phrasebook.py")
        }
        do {
            return try JSONDecoder().decode(PhraseBook.self, from: Data(contentsOf: url))
        } catch {
            fatalError("phrasebook.json could not be read: \(error)")
        }
    }

    // MARK: Lookups (the SQL joins, done in memory)

    func phrase(_ id: String) -> Phrase? { phrases.first { $0.id == id } }
    func phrases(in category: String) -> [Phrase] { phrases.filter { $0.category == category } }
    func country(_ code: String) -> Country? { countries.first { $0.code == code } }
    func locale(_ code: String) -> PhraseLocale? { locales.first { $0.code == code } }

    /// The text to show staff for one phrase in one locale.
    ///
    /// Walks the fallback chain like the plan's SQL: es-MX, then es. If no
    /// translation exists anywhere on the chain, it returns the English text
    /// and says so. It never translates anything on the fly.
    func line(_ phraseID: String, in localeCode: String) -> CardLine {
        let english = phrase(phraseID)?.english ?? phraseID
        if localeCode == sourceLocale {
            return CardLine(id: phraseID, english: english, local: english, state: .reviewed)
        }
        var code: String? = localeCode
        while let current = code {
            if let t = translations[current]?[phraseID] {
                let state: CardLine.State = t.status == .humanReviewed ? .reviewed : .unreviewed
                return CardLine(id: phraseID, english: english, local: t.text, state: state)
            }
            code = locale(current)?.parent
        }
        return CardLine(id: phraseID, english: english, local: english, state: .missing)
    }

    /// True while any phrase in this language lacks a native speaker's sign-off.
    func isBeta(_ localeCode: String) -> Bool {
        phrases.contains { line($0.id, in: localeCode).isBeta }
    }

    /// "French (Français)", plus "beta" when not fully reviewed.
    func displayName(forLocale code: String) -> String {
        guard let l = locale(code) else { return code }
        let name = l.name == l.nativeName ? l.name : "\(l.name) (\(l.nativeName))"
        return isBeta(code) ? "\(name) · beta" : name
    }
}

/// One line on a card: what staff read, plus the English so the user can see
/// what is being claimed.
struct CardLine: Identifiable, Hashable {
    enum State {
        case reviewed    // a native speaker signed it off
        case unreviewed  // AI draft: beta
        case missing     // no translation yet: English is shown instead
    }

    let id: String
    let english: String
    let local: String
    let state: State

    var isBeta: Bool { state != .reviewed }
}

extension Array where Element == CardLine {
    var anyBeta: Bool { contains { $0.isBeta } }
    var anyMissing: Bool { contains { $0.state == .missing } }
}
