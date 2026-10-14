import SwiftUI
import UIKit

/// One phrase as staff see it: the local language big, English small
/// underneath so the user can check what is being claimed.
struct PhraseLineView: View {
    let line: CardLine
    var localFont: Font = .title2
    var localWeight: Font.Weight = .semibold
    /// Kept readable: the user checks the English while the waiter reads.
    var englishFont: Font = .subheadline

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(line.local)
                .font(localFont.weight(localWeight))
                .fixedSize(horizontal: false, vertical: true)
            if line.local != line.english {
                Text(line.english)
                    .font(englishFont)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beta translation").font(.subheadline.weight(.semibold))
                    Text(lines.anyMissing
                         ? "Some lines are not translated yet and will show in English. Others may be AI drafts not yet checked by a native speaker."
                         : "Some lines are AI drafts not yet checked by a native speaker.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .cardSurface(padding: 14)
            .overlay(alignment: .leading) {
                // Orange edge marks it as a warning without shouting.
                UnevenRoundedRectangle(topLeadingRadius: Theme.cornerRadius, bottomLeadingRadius: Theme.cornerRadius)
                    .fill(.orange)
                    .frame(width: 5)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }
}

/// Small orange "BETA" tag for languages not yet checked by a native speaker.
struct BetaBadge: View {
    var body: some View {
        Text("BETA")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(.orange)
            .background(.orange.opacity(0.15), in: Capsule())
            .accessibilityLabel("Beta translation")
    }
}

/// Lays children out left to right and wraps onto new lines, like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = fittedSize(subviews[index], width: bounds.width)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = fittedSize(subviews[index], width: width)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }

    /// Natural size, but never wider than the row (long text wraps instead).
    private func fittedSize(_ view: LayoutSubview, width: CGFloat) -> CGSize {
        let natural = view.sizeThatFits(.unspecified)
        guard natural.width > width else { return natural }
        return view.sizeThatFits(ProposedViewSize(width: width, height: nil))
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
