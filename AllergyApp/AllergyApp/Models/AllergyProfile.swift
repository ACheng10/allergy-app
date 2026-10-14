import Foundation
import SwiftData

/// The user's saved profile. One row, stored on the phone.
///
/// SQL analogy: `@Model` turns this class into a table (SwiftData writes it to
/// SQLite for you), and each stored property is a column.
///
/// Every property has a default value on purpose: iCloud sync (CloudKit)
/// refuses models with required columns or unique constraints. Keeping it
/// this way means turning sync on later is a settings change, not a rewrite.
@Model
final class AllergyProfile {
    /// Phrase ids from the "allergen" category, e.g. "allergen.peanut".
    var allergenIDs: [String] = []
    /// Optional, only used to greet the user on My Card.
    var userName: String = ""
    var severityRaw: String = Severity.anaphylaxis.rawValue
    var countryCode: String = ""
    var localeCode: String = ""
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""
    /// Two-letter country code for the contact's phone, e.g. "GB" for +44.
    var emergencyContactRegion: String = ""
    var setupComplete: Bool = false
    var createdAt: Date = Date()

    init() {}

    var severity: Severity {
        get { Severity(rawValue: severityRaw) ?? .anaphylaxis }
        set { severityRaw = newValue.rawValue }
    }

    /// The number to dial, with the country code in front.
    var emergencyContactDialNumber: String {
        DialCode.international(region: emergencyContactRegion, local: emergencyContactPhone)
    }

    var hasDestination: Bool { !countryCode.isEmpty && !localeCode.isEmpty }

    /// Enough filled in to show a card.
    var isUsable: Bool { !allergenIDs.isEmpty && hasDestination }
}

enum Severity: String, CaseIterable, Identifiable {
    case anaphylaxis
    case severe
    case intolerance

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anaphylaxis: "Severe, can be life-threatening"
        case .severe: "Severe, even traces make me ill"
        case .intolerance: "Intolerance, not life-threatening"
        }
    }

    /// Which intro phrases this severity puts on the card.
    var introPhraseIDs: [String] {
        switch self {
        case .anaphylaxis: ["intro.severe", "intro.life_threatening"]
        case .severe: ["intro.severe"]
        case .intolerance: ["intro.intolerance"]
        }
    }
}
