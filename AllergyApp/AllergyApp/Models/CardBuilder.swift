import Foundation

/// Assembles the card for one profile in one language.
///
/// Python analogy: a pure function `build_card(profile, book) -> list[Section]`.
/// No UI in here, so it is the easiest part to unit test later.
struct CardBuilder {
    struct Section: Identifiable {
        let id: String
        let title: String
        let lines: [CardLine]
    }

    let book: PhraseBook
    let allergenIDs: [String]
    let severity: Severity
    let localeCode: String

    /// Cross-contact lines shown for allergies. Intolerances skip them; the
    /// user's friends should confirm that choice.
    static let crossContactIDs = [
        "cross_contact.intro",
        "cross_contact.fryer",
        "cross_contact.pan",
        "cross_contact.board_knife",
        "cross_contact.separate",
        "cross_contact.remove_not_ok",
    ]

    /// Allergens in the phrase file's order, not the order the user tapped them.
    var orderedAllergenIDs: [String] {
        let chosen = Set(allergenIDs)
        return book.phrases(in: "allergen").map(\.id).filter { chosen.contains($0) }
    }

    var hiddenIDs: [String] {
        var seen = Set<String>()
        var result = ["hidden.all_forms"]
        for allergen in orderedAllergenIDs {
            for hidden in book.hiddenByAllergen[allergen] ?? [] where seen.insert(hidden).inserted {
                result.append(hidden)
            }
        }
        return result
    }

    var sections: [Section] {
        func lines(_ ids: [String]) -> [CardLine] { ids.map { book.line($0, in: localeCode) } }

        var result = [
            Section(id: "intro", title: "Introduction",
                    lines: lines(["intro.hello", "intro.please_read", "intro.allergic_to"])),
            Section(id: "allergens", title: "My allergens", lines: lines(orderedAllergenIDs)),
            Section(id: "severity", title: "How serious",
                    lines: lines(severity.introPhraseIDs + ["intro.not_preference"])),
            Section(id: "hidden", title: "Hidden ingredients", lines: lines(hiddenIDs)),
        ]
        if severity != .intolerance {
            result.append(Section(id: "cross_contact", title: "Kitchen", lines: lines(Self.crossContactIDs)))
        }
        result.append(Section(id: "thanks", title: "Thanks", lines: lines(["intro.thank_you_care"])))
        return result
    }

    var allLines: [CardLine] { sections.flatMap(\.lines) }
}
