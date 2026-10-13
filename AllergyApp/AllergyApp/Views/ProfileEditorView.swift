import SwiftUI

/// First-run setup and the Profile tab: allergens, severity, destination,
/// emergency contact. Changes save automatically.
struct ProfileEditorView: View {
    // @Bindable: like passing a mutable object by reference in Python. Editing
    // a field here writes straight to the database row.
    @Bindable var profile: AllergyProfile
    let isOnboarding: Bool
    @Environment(\.phraseBook) private var book

    var body: some View {
        Form {
            Section {
                DestinationButton(profile: profile, inForm: true)
            } header: {
                Text("Where are you going?")
            }

            Section {
                ForEach(AllergenGroup.resolved(in: book), id: \.group.id) { entry in
                    AllergenGroupRow(group: entry.group, phrases: entry.phrases, profile: profile)
                }
            } header: {
                Text("What are you allergic to?")
            } footer: {
                Text("Open a group to pick the specific foods.")
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
                    NavigationLink("Report a problem") {
                        ReportProblemView(profile: profile)
                    }
                }

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

}

/// One collapsible group, e.g. "Nuts · 2 selected", with its foods inside.
private struct AllergenGroupRow: View {
    let group: AllergenGroup
    let phrases: [PhraseBook.Phrase]
    @Bindable var profile: AllergyProfile
    @State private var expanded = false

    private var selectedCount: Int {
        phrases.filter { profile.allergenIDs.contains($0.id) }.count
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ForEach(phrases) { allergen in
                let selected = profile.allergenIDs.contains(allergen.id)
                Button {
                    toggle(allergen.id)
                } label: {
                    HStack {
                        Text(allergen.english)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                            .font(.title3)
                    }
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                // Plain style keeps the text black instead of tinted like a link.
                .buttonStyle(.plain)
            }
        } label: {
            HStack {
                Label(group.title, systemImage: group.symbol)
                Spacer()
                if selectedCount > 0 {
                    Text("\(selectedCount) selected")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
            }
        }
        .onAppear { if selectedCount > 0 { expanded = true } }
    }

    private func toggle(_ id: String) {
        if let index = profile.allergenIDs.firstIndex(of: id) {
            profile.allergenIDs.remove(at: index)
        } else {
            profile.allergenIDs.append(id)
        }
    }
}
