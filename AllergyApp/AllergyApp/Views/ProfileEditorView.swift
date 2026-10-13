import SwiftUI

/// First-run setup and the Profile tab: allergens, severity, destination,
/// emergency contact. Changes save automatically.
struct ProfileEditorView: View {
    // @Bindable: like passing a mutable object by reference in Python. Editing
    // a field here writes straight to the database row.
    @Bindable var profile: AllergyProfile
    let isOnboarding: Bool
    @Environment(\.phraseBook) private var book

    private var sortedCountries: [PhraseBook.Country] {
        book.countries.sorted { $0.name < $1.name }
    }

    var body: some View {
        Form {
            Section {
                Picker("Country", selection: $profile.countryCode) {
                    Text("Choose a country").tag("")
                    ForEach(sortedCountries) { country in
                        Text(country.name).tag(country.code)
                    }
                }
                .pickerStyle(.navigationLink)
                .onChange(of: profile.countryCode) { _, newCode in
                    // Most common language first, as in data/country_locales.csv.
                    profile.localeCode = book.country(newCode)?.locales.first ?? ""
                }

                if let country = book.country(profile.countryCode) {
                    Picker("Language", selection: $profile.localeCode) {
                        ForEach(country.locales, id: \.self) { code in
                            Text(book.displayName(forLocale: code)).tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            } header: {
                Text("Where are you going?")
            }

            Section {
                ForEach(book.phrases(in: "allergen")) { allergen in
                    Button {
                        toggle(allergen.id)
                    } label: {
                        HStack {
                            Text(allergen.english).foregroundStyle(.primary)
                            Spacer()
                            if profile.allergenIDs.contains(allergen.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                                    .accessibilityLabel("Selected")
                            }
                        }
                    }
                }
            } header: {
                Text("What are you allergic to?")
            }

            Section {
                Picker("Severity", selection: $profile.severityRaw) {
                    ForEach(Severity.allCases) { severity in
                        Text(severity.label).tag(severity.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("How serious is it?")
            }

            Section {
                TextField("Name", text: $profile.emergencyContactName)
                    .textContentType(.name)
                TextField("Phone, with country code", text: $profile.emergencyContactPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            } header: {
                Text("Emergency contact (optional)")
            }

            if !isOnboarding {
                Section {
                    Text("This app shows fixed phrases written in advance. It does not tell you whether food is safe, and it is not medical advice. Always carry your medication.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
            }
        }
        .navigationTitle(isOnboarding ? "Set up your card" : "Profile")
        .toolbar {
            if isOnboarding {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { profile.setupComplete = true }
                        .disabled(!profile.isUsable)
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if let index = profile.allergenIDs.firstIndex(of: id) {
            profile.allergenIDs.remove(at: index)
        } else {
            profile.allergenIDs.append(id)
        }
    }
}
