import SwiftUI

/// Home screen: one giant "Show to staff" button.
struct MyCardView: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book
    @State private var showingWaiterMode = DebugFlags.showWaiter

    private var card: CardBuilder {
        CardBuilder(book: book, allergenIDs: profile.allergenIDs,
                    severity: profile.severity, localeCode: profile.localeCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DestinationButton(profile: profile, openOnAppear: DebugFlags.showDestinations)

                    Button {
                        showingWaiterMode = true
                    } label: {
                        Label("Show to staff", systemImage: "hand.raised.fill")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, minHeight: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 18))
                    .accessibilityHint("Opens your card full screen in the local language")

                    BetaNotice(lines: card.allLines)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ON YOUR CARD")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout {
                            ForEach(card.orderedAllergenIDs, id: \.self) { id in
                                Text(Self.shortName(book.phrase(id)?.english ?? id))
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                            }
                        }
                        Label(profile.severity.label, systemImage: "exclamationmark.shield")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Card")
            .fullScreenCover(isPresented: $showingWaiterMode) {
                WaiterModeView(card: card)
            }
        }
    }

    /// "Shellfish such as shrimp, prawns..." becomes "Shellfish" for the chips.
    static func shortName(_ english: String) -> String {
        var name = english
        for marker in [", such as", " such as", " (", " and all"] {
            if let range = name.range(of: marker) { name = String(name[..<range.lowerBound]) }
        }
        return name
    }
}
