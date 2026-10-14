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

    @State private var appeared = false

    private var greeting: String {
        let name = profile.userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "My Card" : "Hi, \(name)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DestinationButton(profile: profile, openOnAppear: DebugFlags.showDestinations)

                    heroCard

                    BetaNotice(lines: card.allLines)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
            .fullScreenCover(isPresented: $showingWaiterMode) {
                WaiterModeView(card: card)
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showingWaiterMode) { _, open in open }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) { appeared = true }
            }
        }
    }

    /// The card itself: a preview of what staff will see, and the button that shows it.
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ALLERGY CARD")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .opacity(0.8)

            FlowLayout {
                ForEach(Array(card.orderedAllergenIDs.enumerated()), id: \.element) { index, id in
                    Text(Self.shortName(book.phrase(id)?.english ?? id))
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.18), in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.25)))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05),
                                   value: appeared)
                }
            }

            Label(profile.severity.label, systemImage: "exclamationmark.shield.fill")
                .font(.subheadline.weight(.medium))
                .opacity(0.9)

            Button {
                showingWaiterMode = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "hand.raised.fill")
                        .symbolEffect(.bounce, value: appeared)
                    Text("Show to staff")
                }
                .font(.title3.bold())
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint("Opens your card in the local language")
        }
        .foregroundStyle(.white)
        .padding(20)
        .background {
            ZStack {
                Theme.brand
                // Soft light in one corner so the card has depth, not a flat fill.
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 260)
                    .blur(radius: 30)
                    .offset(x: 120, y: -110)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius + 4, style: .continuous))
        }
        .shadow(color: Color.accentColor.opacity(0.35), radius: 18, y: 10)
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
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
