import SwiftUI

/// Free forever, works offline, one tap from every screen (it is a tab).
struct EmergencyView: View {
    let profile: AllergyProfile
    @Environment(\.phraseBook) private var book

    var body: some View {
        let country = book.country(profile.countryCode)
        let lines = book.phrases(in: "emergency")
            .filter { $0.id != "emergency.contact" || !profile.emergencyContactPhone.isEmpty }
            .map { book.line($0.id, in: profile.localeCode) }

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let country {
                        callButtons(for: country)
                    }
                    if !profile.emergencyContactPhone.isEmpty {
                        callButton(
                            title: "Call \(profile.emergencyContactName.isEmpty ? "emergency contact" : profile.emergencyContactName)",
                            number: profile.emergencyContactPhone, tint: .blue)
                    }

                    BetaNotice(lines: lines)

                    Text("Show this to people nearby")
                        .font(.headline)
                    ForEach(lines) { line in
                        PhraseLineView(line: line, localFont: .title)
                    }
                }
                .padding()
            }
            .navigationTitle("Emergency")
        }
        .onAppear { FullBrightness.on() }
        .onDisappear { FullBrightness.off() }
    }

    @ViewBuilder
    private func callButtons(for country: PhraseBook.Country) -> some View {
        callButton(title: "Call \(country.emergencyNumber)", number: country.emergencyNumber, tint: .red)
        if country.ambulanceNumber != country.emergencyNumber {
            callButton(title: "Ambulance \(country.ambulanceNumber)", number: country.ambulanceNumber, tint: .red)
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
    private func callButton(title: String, number: String, tint: Color) -> some View {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if !digits.isEmpty, let url = URL(string: "tel:\(digits)") {
            Link(destination: url) {
                Label(title, systemImage: "phone.fill")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
        }
    }
}
