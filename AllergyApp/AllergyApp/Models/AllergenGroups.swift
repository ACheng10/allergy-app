import Foundation

/// How the allergen picker is grouped. Ids not listed here land in "Other",
/// so adding a row to data/phrases_en.csv never hides it.
struct AllergenGroup: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let allergenIDs: [String]

    static let all: [AllergenGroup] = [
        AllergenGroup(id: "nuts", title: "Nuts", symbol: "leaf", allergenIDs: [
            "allergen.tree_nuts", "allergen.almond", "allergen.hazelnut", "allergen.walnut",
            "allergen.cashew", "allergen.pecan", "allergen.brazil_nut", "allergen.pistachio",
            "allergen.macadamia", "allergen.pine_nut", "allergen.coconut",
        ]),
        AllergenGroup(id: "peanuts_legumes", title: "Peanuts and legumes", symbol: "circle.grid.2x1", allergenIDs: [
            "allergen.peanut", "allergen.soy", "allergen.legumes", "allergen.lupin",
        ]),
        AllergenGroup(id: "seafood", title: "Fish and seafood", symbol: "fish", allergenIDs: [
            "allergen.fish", "allergen.crustaceans", "allergen.molluscs",
        ]),
        AllergenGroup(id: "dairy_eggs", title: "Milk and eggs", symbol: "drop", allergenIDs: [
            "allergen.milk", "allergen.egg",
        ]),
        AllergenGroup(id: "grains", title: "Grains", symbol: "takeoutbag.and.cup.and.straw", allergenIDs: [
            "allergen.gluten", "allergen.wheat", "allergen.buckwheat", "allergen.corn",
        ]),
        AllergenGroup(id: "seeds_veg", title: "Seeds and vegetables", symbol: "carrot", allergenIDs: [
            "allergen.sesame", "allergen.mustard", "allergen.celery",
        ]),
        AllergenGroup(id: "other", title: "Other", symbol: "ellipsis.circle", allergenIDs: [
            "allergen.sulphites", "allergen.kiwi", "allergen.red_meat",
        ]),
    ]

    /// Extra words people search for that the English label does not contain,
    /// e.g. "prawn" finds shellfish, "dairy" finds milk.
    static let searchTerms: [String: [String]] = [
        "allergen.peanut": ["groundnut", "monkey nut", "arachis"],
        "allergen.tree_nuts": ["tree nut"],
        "allergen.pine_nut": ["pignoli", "pinenut"],
        "allergen.milk": ["dairy", "cheese", "butter", "cream", "yoghurt", "yogurt", "lactose", "casein", "whey"],
        "allergen.egg": ["albumin", "mayonnaise"],
        "allergen.fish": ["salmon", "tuna", "cod", "anchovy", "fish sauce"],
        "allergen.crustaceans": ["crayfish", "langoustine", "scampi", "crustacean"],
        "allergen.molluscs": ["shellfish", "scallop", "snail", "calamari", "mollusk", "cuttlefish", "oyster sauce"],
        "allergen.soy": ["soybean", "tofu", "edamame", "miso", "soy sauce"],
        "allergen.gluten": ["coeliac", "celiac", "barley", "rye", "oats"],
        "allergen.wheat": ["flour", "bread", "pasta", "noodles"],
        "allergen.sesame": ["tahini"],
        "allergen.legumes": ["beans", "lentil", "chickpea", "pea"],
        "allergen.lupin": ["lupine"],
        "allergen.corn": ["maize", "polenta"],
        "allergen.celery": ["celeriac"],
        "allergen.buckwheat": ["soba"],
        "allergen.sulphites": ["sulfur", "sulphur", "wine"],
        "allergen.kiwi": ["kiwifruit"],
        "allergen.red_meat": ["beef", "pork", "lamb", "alpha-gal", "gelatine", "mammal"],
    ]

    /// Allergens whose label, group or search terms contain the query.
    /// Case and accents are ignored.
    static func search(_ query: String, in book: PhraseBook) -> [PhraseBook.Phrase] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return resolved(in: book).flatMap { entry in
            entry.phrases.filter { phrase in
                ([phrase.english, entry.group.title] + (searchTerms[phrase.id] ?? []))
                    .contains { $0.localizedStandardContains(query) }
            }
        }
    }

    /// Groups resolved against the phrase book, with leftovers added to "Other".
    static func resolved(in book: PhraseBook) -> [(group: AllergenGroup, phrases: [PhraseBook.Phrase])] {
        let phrases = book.phrases(in: "allergen")
        let listed = Set(all.flatMap(\.allergenIDs))
        let leftovers = phrases.filter { !listed.contains($0.id) }
        return all.map { group in
            var items = group.allergenIDs.compactMap { id in phrases.first { $0.id == id } }
            if group.id == "other" { items += leftovers }
            return (group, items)
        }.filter { !$0.phrases.isEmpty }
    }
}
