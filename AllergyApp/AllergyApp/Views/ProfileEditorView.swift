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
                ForEach(book.phrases(in: "allergen")) { allergen in
                    Button {
                        toggle(allergen.id)
                    } label: {
                        let selected = profile.allergenIDs.contains(allergen.id)
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

    private func toggle(_ id: String) {
        if let index = profile.allergenIDs.firstIndex(of: id) {
            profile.allergenIDs.remove(at: index)
        } else {
            profile.allergenIDs.append(id)
        }
    }
}
