import SwiftUI

/// The screen the user hands to staff. Full brightness, local language large,
/// English small. No beta warnings here: those are for the user, not the waiter.
struct WaiterModeView: View {
    let card: CardBuilder
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(card.sections) { section in
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(section.lines) { line in
                                PhraseLineView(line: line,
                                               localFont: section.id == "allergens" ? .largeTitle : .title2)
                            }
                        }
                        Divider()
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
}
