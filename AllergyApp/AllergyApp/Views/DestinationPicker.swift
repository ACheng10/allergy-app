import SwiftUI

/// One-tap destination switcher: every country with its languages as buttons.
/// Tapping "Switzerland > French" sets both and closes the sheet.
struct DestinationPicker: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    /// Current country first, then alphabetical; filtered by the search box.
    private var countries: [PhraseBook.Country] {
        let sorted = book.countries.sorted { $0.name < $1.name }
        let matches = search.isEmpty ? sorted : sorted.filter {
            $0.name.localizedCaseInsensitiveContains(search)
        }
        let current = matches.filter { $0.code == profile.countryCode }
        return current + matches.filter { $0.code != profile.countryCode }
    }

    var body: some View {
        NavigationStack {
            List(countries) { country in
                VStack(alignment: .leading, spacing: 8) {
                    Text(country.name).font(.headline)
                    FlowingButtons(codes: country.locales) { code in
                        choose(country: country.code, locale: code)
                    } label: { code in
                        let selected = profile.countryCode == country.code && profile.localeCode == code
                        Label(book.displayName(forLocale: code),
                              systemImage: selected ? "checkmark.circle.fill" : "circle")
                    }
                }
                .padding(.vertical, 4)
            }
            .searchable(text: $search, prompt: "Search countries")
            .navigationTitle("Where are you?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func choose(country: String, locale: String) {
        profile.countryCode = country
        profile.localeCode = locale
        dismiss()
    }
}

/// Language buttons that wrap onto new lines when they don't fit.
private struct FlowingButtons<Label: View>: View {
    let codes: [String]
    let action: (String) -> Void
    @ViewBuilder let label: (String) -> Label

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { buttons }
            VStack(alignment: .leading) { buttons }
        }
    }

    private var buttons: some View {
        ForEach(codes, id: \.self) { code in
            Button { action(code) } label: { label(code) }
                .buttonStyle(.bordered)
        }
    }
}

/// The tappable "Switzerland · French" chip shown at the top of screens.
struct DestinationButton: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Image(systemName: "globe")
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.country(profile.countryCode)?.name ?? "Choose a country")
                        .font(.headline)
                    Text(book.displayName(forLocale: profile.localeCode))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Change").font(.subheadline.weight(.semibold))
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Change the country and language")
        .sheet(isPresented: $showingPicker) {
            DestinationPicker(profile: profile)
        }
    }
}
