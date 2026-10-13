import SwiftUI

/// Home screen: one giant "Show to staff" button.
struct MyCardView: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book
    @State private var showingWaiterMode = false

    private var card: CardBuilder {
        CardBuilder(book: book, allergenIDs: profile.allergenIDs,
                    severity: profile.severity, localeCode: profile.localeCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DestinationButton(profile: profile)

                    Button {
                        showingWaiterMode = true
                    } label: {
                        Label("Show to staff", systemImage: "hand.raised.fill")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, minHeight: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Opens your card full screen in the local language")

                    BetaNotice(lines: card.allLines)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your card says you are allergic to").font(.headline)
                        ForEach(card.orderedAllergenIDs, id: \.self) { id in
                            Text("• \(book.phrase(id)?.english ?? id)")
                        }
                        Text(profile.severity.label)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("My Card")
            .fullScreenCover(isPresented: $showingWaiterMode) {
                WaiterModeView(card: card)
            }
        }
    }
}
