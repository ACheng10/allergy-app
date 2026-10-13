import SwiftData
import SwiftUI

/// The app's entry point, like `if __name__ == "__main__":` in Python.
@main
struct AllergyApp: App {
    /// The on-device database. iCloud sync is off until you have a paid
    /// Apple Developer account; see docs/ICLOUD_SYNC.md for the one-line switch.
    let container: ModelContainer = {
        let config = ModelConfiguration(cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: AllergyProfile.self, configurations: config)
        } catch {
            fatalError("Could not open the on-device database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

/// Makes the phrase book available to every screen as
/// `@Environment(\.phraseBook)`, loaded once from the app bundle.
private struct PhraseBookKey: EnvironmentKey {
    static let defaultValue = PhraseBook.loadBundled()
}

extension EnvironmentValues {
    var phraseBook: PhraseBook {
        get { self[PhraseBookKey.self] }
        set { self[PhraseBookKey.self] = newValue }
    }
}
