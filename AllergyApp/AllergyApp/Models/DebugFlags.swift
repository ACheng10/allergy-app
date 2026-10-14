import Foundation

/// Launch arguments used by the Simulator screenshot job (smoke.yml) to open
/// specific screens with a sample profile. They do nothing in release builds.
///
///   -demo              fill in a sample profile (Hong Kong, Cantonese)
///   -tab N             open tab N (0 My Card, 1 Ask, 2 Emergency, 3 Profile)
///   -showDestinations  open the country picker
///   -showWaiter        open Waiter Mode
enum DebugFlags {
    #if DEBUG
    private static let args = ProcessInfo.processInfo.arguments
    static let demo = args.contains("-demo")
    static let showDestinations = args.contains("-showDestinations")
    static let showWaiter = args.contains("-showWaiter")
    static let startTab: Int = {
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return 0 }
        return Int(args[i + 1]) ?? 0
    }()
    #else
    static let demo = false
    static let showDestinations = false
    static let showWaiter = false
    static let startTab = 0
    #endif

    static func applyDemo(to profile: AllergyProfile) {
        profile.countryCode = "HK"
        profile.localeCode = "yue-Hant"
        profile.allergenIDs = ["allergen.peanut", "allergen.tree_nuts", "allergen.crustaceans", "allergen.milk"]
        profile.severity = .anaphylaxis
        profile.userName = "Alex"
        profile.emergencyContactName = "Sam"
        profile.emergencyContactRegion = "GB"
        profile.emergencyContactPhone = "07700 900000"
        profile.setupComplete = true
    }
}
