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

    private func lines(_ ids: [String]) -> [CardLine] { ids.map { book.line($0, in: localeCode) } }

    /// What the waiter sees first: who, what, how bad, and one ask. A waiter on
    /// a busy shift reads about four lines, so everything else waits for the kitchen.
    var shortSections: [Section] {
        [
            Section(id: "allergic_to", title: "Allergic to", lines: lines(["intro.allergic_to"])),
            Section(id: "allergens", title: "My allergens", lines: lines(orderedAllergenIDs)),
            Section(id: "ask", title: "Please check",
                    lines: lines(severity.introPhraseIDs + ["hidden.all_forms", "question.ingredients"])),
        ]
    }

    /// The detail for the chef: specific hidden ingredients and how to avoid
    /// cross-contact. Shown behind a button in Waiter Mode.
    var kitchenSections: [Section] {
        var result = [
            Section(id: "hidden", title: "Hidden ingredients",
                    lines: lines(hiddenIDs.filter { $0 != "hidden.all_forms" })),
        ]
        if severity != .intolerance {
            result.append(Section(id: "cross_contact", title: "Kitchen", lines: lines(Self.crossContactIDs)))
        }
        result.append(Section(id: "thanks", title: "Thanks",
                              lines: lines(["intro.not_preference", "intro.thank_you_care"])))
        return result.filter { !$0.lines.isEmpty }
    }

    var sections: [Section] { shortSections + kitchenSections }

    var allLines: [CardLine] { sections.flatMap(\.lines) }
}
