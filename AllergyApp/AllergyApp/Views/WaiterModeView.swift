import SwiftUI

/// The screen the user hands to staff. Full brightness, local language large,
/// English small. No beta warnings here: those are for the user, not the waiter.
struct WaiterModeView: View {
    let card: CardBuilder
    @Environment(\.dismiss) private var dismiss
    @State private var showKitchen = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(card.shortSections) { section in
                        sectionView(section)
                    }

                    Button {
                        withAnimation { showKitchen.toggle() }
                    } label: {
                        Label(showKitchen ? "Hide kitchen details" : "More for the kitchen",
                              systemImage: showKitchen ? "chevron.up" : "frying.pan")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .buttonStyle(.bordered)

                    if showKitchen {
                        ForEach(card.kitchenSections) { section in
                            sectionView(section)
                        }
                    }

                    NavigationLink {
                        ConversationView(localeCode: card.localeCode)
                    } label: {
                        Label("Ask a question", systemImage: "bubble.left.and.bubble.right")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { FullBrightness.on() }
        .onDisappear { FullBrightness.off() }
    }

    /// Three text sizes only, so the eye knows where to go:
    /// allergens largest and bold, the heading and severity next, everything else body.
    @ViewBuilder
    private func sectionView(_ section: CardBuilder.Section) -> some View {
        switch section.id {
        case "allergic_to":
            // Heading for the allergen list right below it.
            ForEach(section.lines) { line in
                PhraseLineView(line: line, localFont: .title2, localWeight: .bold)
            }
        case "allergens":
            VStack(alignment: .leading, spacing: 18) {
                ForEach(section.lines) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        PhraseLineView(line: line, localFont: .largeTitle, localWeight: .bold)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.red.opacity(0.35), lineWidth: 2))
        case "ask":
            VStack(alignment: .leading, spacing: 16) {
                ForEach(section.lines) { line in
                    if card.severity.introPhraseIDs.contains(line.id) {
                        // How serious it is: the line a waiter must not skim past.
                        Label {
                            PhraseLineView(line: line, localFont: .title2, localWeight: .bold)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                        }
                    } else {
                        PhraseLineView(line: line, localFont: .title3, localWeight: .regular)
                    }
                }
            }
        default:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(section.lines) { line in
                    PhraseLineView(line: line, localFont: .title3, localWeight: .regular)
                }
                Divider()
            }
        }
    }
}
