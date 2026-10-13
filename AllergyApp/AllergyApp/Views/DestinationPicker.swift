import SwiftUI

/// Country list, then language list (only when a country has more than one).
/// Countries with one language are a single tap.
struct DestinationPicker: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var results: [PhraseBook.Country] {
        let sorted = book.countries.sorted { $0.name < $1.name }
        guard !search.isEmpty else { return sorted }
        return sorted.filter { country in
            country.name.localizedCaseInsensitiveContains(search)
                || country.locales.contains { book.languageName($0).localizedCaseInsensitiveContains(search) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty, let current = book.country(profile.countryCode) {
                    Section("Current") { row(for: current) }
                }
                Section(search.isEmpty ? "All countries" : "Results") {
                    ForEach(results) { row(for: $0) }
                }
            }
            .searchable(text: $search, prompt: "Country or language")
            .navigationTitle("Where are you?")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PhraseBook.Country.self) { country in
                LanguageList(profile: profile, country: country) { dismiss() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for country: PhraseBook.Country) -> some View {
        let label = CountryRow(country: country, isCurrent: country.code == profile.countryCode)
        if country.locales.count == 1, let only = country.locales.first {
            Button {
                profile.countryCode = country.code
                profile.localeCode = only
                dismiss()
            } label: { label }
            .tint(.primary)
        } else {
            NavigationLink(value: country) { label }
        }
    }
}

private struct CountryRow: View {
    let country: PhraseBook.Country
    let isCurrent: Bool
    @Environment(\.phraseBook) private var book

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                Text(country.locales.map(book.languageName).joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isCurrent {
                Image(systemName: "checkmark").foregroundStyle(.tint)
            }
        }
    }
}

private struct LanguageList: View {
    @Bindable var profile: AllergyProfile
    let country: PhraseBook.Country
    let onDone: () -> Void
    @Environment(\.phraseBook) private var book

    var body: some View {
        List(country.locales, id: \.self) { code in
            Button {
                profile.countryCode = country.code
                profile.localeCode = code
                onDone()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.languageName(code))
                        if let native = book.locale(code)?.nativeName, native != book.languageName(code) {
                            Text(native).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if book.isBeta(code) { BetaBadge() }
                    if profile.countryCode == country.code && profile.localeCode == code {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            .tint(.primary)
        }
        .navigationTitle("\(country.flag) \(country.name)")
    }
}

/// The current destination, tappable to change it.
struct DestinationButton: View {
    @Bindable var profile: AllergyProfile
    /// Plain row for use inside a Form; otherwise a rounded card.
    var inForm = false
    var openOnAppear = false
    @Environment(\.phraseBook) private var book
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 12) {
                Text(book.country(profile.countryCode)?.flag ?? "🌍").font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.country(profile.countryCode)?.name ?? "Choose a country")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !profile.localeCode.isEmpty {
                        HStack(spacing: 6) {
                            Text(book.languageName(profile.localeCode))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if book.isBeta(profile.localeCode) { BetaBadge() }
                        }
                    }
                }
                Spacer()
                Text("Change")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            .padding(inForm ? 0 : 14)
            .background {
                if !inForm {
                    RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Change the country and language")
        .sheet(isPresented: $showingPicker) {
            DestinationPicker(profile: profile)
        }
        .onAppear { if openOnAppear { showingPicker = true } }
    }
}
