import SwiftUI

/// Free forever, works offline, one tap from every screen (it is a tab).
struct EmergencyView: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book

    /// What a bystander needs, in the order of St John Ambulance's anaphylaxis first aid:
    /// auto-injector first, then the ambulance, then position and a second dose.
    static let phraseIDs = [
        "emergency.reaction",
        "emergency.autoinjector",
        "emergency.help_inject",
        "emergency.thigh",
        "emergency.call_ambulance",
        "emergency.lie_down",
        "emergency.sit_if_breathing",
        "emergency.second_dose",
        "emergency.contact",
    ]

    var body: some View {
        let country = book.country(profile.countryCode)
        let lines = Self.phraseIDs
            .filter { $0 != "emergency.contact" || !profile.emergencyContactPhone.isEmpty }
            .map { book.line($0, in: profile.localeCode) }

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DestinationButton(profile: profile)
                    if let country {
                        callButtons(for: country)
                    }
                    if !profile.emergencyContactPhone.isEmpty {
                        callButton(
                            title: "Call \(profile.emergencyContactName.isEmpty ? "emergency contact" : profile.emergencyContactName)",
                            number: profile.emergencyContactDialNumber, gradient: Theme.contact,
                            subtitle: profile.emergencyContactDialNumber, systemImage: "person.fill")
                    }

                    BetaNotice(lines: lines)

                    Text("Show this to people nearby")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                // Numbered, because the order matters in first aid.
                                Text("\(index + 1)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Theme.danger, in: Circle())
                                VStack(alignment: .leading, spacing: 6) {
                                    PhraseLineView(line: line, localFont: .title)
                                    if line.id == "emergency.contact" {
                                        // So a bystander can call from their own phone.
                                        Text(contactLabel)
                                            .font(.title.bold())
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                            if index < lines.count - 1 { Divider().padding(.leading, 44) }
                        }
                    }
                    .cardSurface(padding: 18)
                }
                .padding()
            }
            .navigationTitle("Emergency")
        }
        .onAppear { FullBrightness.on() }
        .onDisappear { FullBrightness.off() }
    }

    private var contactLabel: String {
        let number = profile.emergencyContactDialNumber
        return profile.emergencyContactName.isEmpty ? number : "\(profile.emergencyContactName): \(number)"
    }

    @ViewBuilder
    private func callButtons(for country: PhraseBook.Country) -> some View {
        callButton(title: "Call \(country.emergencyNumber)", number: country.emergencyNumber,
                   gradient: Theme.danger, subtitle: "Emergency services", systemImage: "phone.fill")
        if country.ambulanceNumber != country.emergencyNumber {
            callButton(title: "Ambulance \(country.ambulanceNumber)", number: country.ambulanceNumber,
                       gradient: Theme.danger, systemImage: "cross.case.fill")
        }
        if !country.emergencyNote.isEmpty {
            Text("\(country.name): \(country.emergencyNote)")
                .font(.footnote)
        }
        if !country.numbersVerified {
            // Release blocker: see data/countries.csv. Remove once every row is verified.
            Text("Emergency numbers not yet verified against an official source.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func callButton(title: String, number: String, gradient: LinearGradient,
                            subtitle: String? = nil, systemImage: String = "phone.fill") -> some View {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if !digits.isEmpty, let url = URL(string: "tel:\(digits)") {
            Link(destination: url) {
                GradientButtonLabel(title: title, systemImage: systemImage, subtitle: subtitle,
                                    gradient: gradient, minHeight: 76)
            }
            .buttonStyle(PressableStyle())
        }
    }

}
