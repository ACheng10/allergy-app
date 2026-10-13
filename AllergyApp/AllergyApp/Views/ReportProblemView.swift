import SwiftUI

/// Profile > Report a problem. Sends a short report that becomes a GitHub
/// issue, where Claude diagnoses it and suggests fixes for the developer.
struct ReportProblemView: View {
    let profile: AllergyProfile
    @Environment(\.dismiss) private var dismiss

    @State private var screen = "My Card"
    @State private var message = ""
    @State private var includeAllergens = false
    @State private var sending = false
    @State private var errorText: String?
    @State private var sent = false

    private static let screens = ["My Card", "Waiter Mode", "Ask", "Emergency", "Profile", "A translation", "Other"]

    private var canSend: Bool {
        ReportConfig.endpoint != nil && !sending
            && message.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5
    }

    var body: some View {
        Form {
            if ReportConfig.endpoint == nil {
                Section {
                    Text(ReportError.notConfigured.errorDescription ?? "")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Where did it happen?") {
                Picker("Screen", selection: $screen) {
                    ForEach(Self.screens, id: \.self) { Text($0).tag($0) }
                }
            }

            Section {
                TextField("Describe what went wrong", text: $message, axis: .vertical)
                    .lineLimit(4...10)
            } header: {
                Text("What went wrong?")
            } footer: {
                Text("If a translation is wrong, say which line and what it should say.")
            }

            Section {
                Toggle("Include my allergens", isOn: $includeAllergens)
            } footer: {
                Text("Your app version, iPhone model, country and language are always sent. Allergens are only sent if you switch this on. Reports are read by the developer and an AI assistant. Don't include your name or phone number.")
            }

            Section {
                Button {
                    Task { await send() }
                } label: {
                    if sending {
                        ProgressView()
                    } else {
                        Text("Send report")
                    }
                }
                .disabled(!canSend)
                if let errorText {
                    Text(errorText).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Report a problem")
        .alert("Thanks, report sent", isPresented: $sent) {
            Button("OK") { dismiss() }
        }
    }

    private func send() async {
        sending = true
        errorText = nil
        defer { sending = false }
        let report = ProblemReport.make(screen: screen, message: message,
                                        profile: profile, includeAllergens: includeAllergens)
        do {
            try await report.send()
            sent = true
        } catch {
            errorText = error.localizedDescription
        }
    }
}
