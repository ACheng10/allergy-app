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

    /// One text size throughout so the card reads evenly; only the allergens
    /// are bold, so they stand out without shouting.
    private func sectionView(_ section: CardBuilder.Section) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(section.lines) { line in
                PhraseLineView(line: line, localFont: .title2,
                               localWeight: section.id == "allergens" ? .bold : .regular,
                               englishFont: .title2)
            }
            if section.id != "allergic_to" { Divider() }
        }
    }
}
