import SwiftUI

/// Shared look: colours, card surfaces and the press animation.
///
/// Python analogy: a small style module every screen imports, so changing the
/// brand colour here changes it everywhere.
enum Theme {
    /// Teal to deep blue, built from the app's accent colour.
    static let brand = LinearGradient(
        colors: [Color(red: 0.00, green: 0.55, blue: 0.58), Color(red: 0.05, green: 0.28, blue: 0.55)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let danger = LinearGradient(
        colors: [Color(red: 0.98, green: 0.33, blue: 0.30), Color(red: 0.82, green: 0.10, blue: 0.22)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let contact = LinearGradient(
        colors: [Color(red: 0.25, green: 0.55, blue: 1.00), Color(red: 0.20, green: 0.33, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let cornerRadius: CGFloat = 22
}

/// A white (or dark grey in Dark Mode) rounded surface with a soft shadow.
struct CardSurface: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16) -> some View { modifier(CardSurface(padding: padding)) }
}

/// Shrinks slightly while pressed and springs back, like a physical button.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Big gradient call-to-action, used for "Show to staff" and the call buttons.
struct GradientButtonLabel: View {
    let title: String
    let systemImage: String
    var subtitle: String?
    var gradient: LinearGradient = Theme.brand
    var minHeight: CGFloat = 72

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.2), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.bold())
                if let subtitle {
                    Text(subtitle).font(.subheadline).opacity(0.85)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline)
                .opacity(0.7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .background(gradient, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }
}

/// Light, Dark, or follow the phone. Saved in UserDefaults (a small key-value
/// store on the phone, like a Python dict that survives restarts), not in the
/// profile, because it is a device preference rather than allergy data.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Match iPhone"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Applies the saved appearance to the whole app.
struct AppearanceModifier: ViewModifier {
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system

    func body(content: Content) -> some View {
        content.preferredColorScheme(appearance.colorScheme)
    }
}
