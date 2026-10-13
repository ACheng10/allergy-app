import SwiftUI
import UIKit

/// One phrase as staff see it: the local language big, English small
/// underneath so the user can check what is being claimed.
struct PhraseLineView: View {
    let line: CardLine
    var localFont: Font = .title2

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(line.local)
                .font(localFont.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            if line.local != line.english {
                Text(line.english)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Shown to the user (never inside Waiter Mode) when a card is not fully
/// reviewed by a native speaker.
struct BetaNotice: View {
    let lines: [CardLine]

    var body: some View {
        if lines.anyBeta {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beta translation").font(.headline)
                    Text(lines.anyMissing
                         ? "Some lines are not translated yet and will show in English. Others may be AI drafts not yet checked by a native speaker."
                         : "Some lines are AI drafts not yet checked by a native speaker.")
                        .font(.footnote)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .foregroundStyle(.orange)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// Full brightness and no auto-lock while staff are reading the screen.
/// Restores the user's brightness afterwards. Screens can nest (Waiter Mode
/// opens a question), so it counts how many are open, like a reference count.
@MainActor
enum FullBrightness {
    private static var openScreens = 0
    private static var savedBrightness: CGFloat = 0.5

    private static var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen
    }

    static func on() {
        openScreens += 1
        guard openScreens == 1, let screen else { return }
        savedBrightness = screen.brightness
        screen.brightness = 1.0
        UIApplication.shared.isIdleTimerDisabled = true
    }

    static func off() {
        openScreens = max(0, openScreens - 1)
        guard openScreens == 0 else { return }
        screen?.brightness = savedBrightness
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
