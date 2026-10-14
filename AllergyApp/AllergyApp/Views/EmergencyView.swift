import SwiftUI

/// Free forever, works offline, one tap from every screen (it is a tab).
struct EmergencyView: View {
    @Bindable var profile: AllergyProfile
    @Environment(\.phraseBook) private var book
    @State private var showMore = false

    /// What a bystander needs, in the order of St John Ambulance's anaphylaxis first aid:
    /// auto-injector first, then the ambulance, then position and a second dose.
    static let shortIDs = [
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
        let all = book.phrases(in: "emergency")
            .filter { $0.id != "emergency.contact" || !profile.emergencyContactPhone.isEmpty }
            .map { book.line($0.id, in: profile.localeCode) }
        let short = Self.shortIDs.compactMap { id in all.first { $0.id == id } }
        let more = all.filter { !Self.shortIDs.contains($0.id) }
        let lines = showMore ? all : short

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
                            number: profile.emergencyContactDialNumber, tint: .blue)
                    }

                    BetaNotice(lines: lines)

                    Text("Show this to people nearby")
                        .font(.headline)
                    ForEach(short) { line in
                        PhraseLineView(line: line, localFont: .title)
                        if line.id == "emergency.contact" {
                            // So a bystander can call from their own phone.
                            Text(contactLabel)
                                .font(.title.bold())
                                .textSelection(.enabled)
                        }
                    }

                    if !more.isEmpty {
                        Button {
                            withAnimation { showMore.toggle() }
                        } label: {
                            Label(showMore ? "Fewer phrases" : "More phrases",
                                  systemImage: showMore ? "chevron.up" : "chevron.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.bordered)
                    }

                    if showMore {
                        ForEach(more) { line in
                            PhraseLineView(line: line, localFont: .title)
                        }
                    }
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
