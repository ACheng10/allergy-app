import Foundation
import UIKit

/// Where in-app problem reports go. Fill these in after deploying the worker
/// in reports-worker/ (see docs/REPORTS_SETUP.md). While `endpoint` is nil the
/// Report screen explains that reporting is not set up yet.
enum ReportConfig {
    static let endpoint: URL? = nil  // e.g. URL(string: "https://allergy-card-reports.yourname.workers.dev/report")
    /// Not a real secret (anyone can read it out of the app); it only stops
    /// random web traffic from filing issues.
    static let appKey = ""
}

/// What the app sends. Python analogy: a dataclass you json.dumps().
struct ProblemReport: Encodable {
    struct Context: Encodable {
        let appVersion: String
        let build: String
        let iosVersion: String
        let device: String
        let country: String
        let language: String
        /// Only filled when the user ticks "Include my allergens".
        let allergens: [String]?
    }

    let screen: String
    let message: String
    let context: Context

    @MainActor
    static func make(screen: String, message: String, profile: AllergyProfile, includeAllergens: Bool) -> ProblemReport {
        let info = Bundle.main.infoDictionary ?? [:]
        return ProblemReport(
            screen: screen,
            message: message,
            context: Context(
                appVersion: info["CFBundleShortVersionString"] as? String ?? "?",
                build: info["CFBundleVersion"] as? String ?? "?",
                iosVersion: UIDevice.current.systemVersion,
                device: UIDevice.current.model,
                country: profile.countryCode,
                language: profile.localeCode,
                allergens: includeAllergens ? profile.allergenIDs : nil
            )
        )
    }

    func send() async throws {
        guard let endpoint = ReportConfig.endpoint else { throw ReportError.notConfigured }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ReportConfig.appKey, forHTTPHeaderField: "X-App-Key")
        request.httpBody = try JSONEncoder().encode(self)
        request.timeoutInterval = 20
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ReportError.rejected
        }
    }
}

enum ReportError: LocalizedError {
    case notConfigured
    case rejected

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Reporting isn't set up in this build yet."
        case .rejected: "The report couldn't be sent. Please try again later."
        }
    }
}
