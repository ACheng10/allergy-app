import SwiftUI

/// Two-way card: the user picks a fixed question, staff tap a fixed answer in
/// their own language, and the user sees it in English. No free-text machine
/// translation, on purpose.
struct ConversationView: View {
    let localeCode: String
    @Environment(\.phraseBook) private var book

    var body: some View {
        let questions = book.phrases(in: "question").map { book.line($0.id, in: localeCode) }
        List {
            Section {
                BetaNotice(lines: questions)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Choose a question") {
                ForEach(questions) { question in
                    NavigationLink {
                        QuestionView(question: question, localeCode: localeCode)
                    } label: {
                        PhraseLineView(line: question, localFont: .body)
                    }
                }
            }
        }
        .navigationTitle("Ask staff")
    }
}

struct QuestionView: View {
    let question: CardLine
    let localeCode: String
    @Environment(\.phraseBook) private var book
    @State private var answer: CardLine?

    /// Answers that need the user to stop and think get a colour.
    private static let tone: [String: Color] = [
        "staff_answer.safe": .green,
        "staff_answer.no": .gray,
        "staff_answer.not_safe": .red,
        "staff_answer.contains_allergen": .red,
        "staff_answer.may_contain": .orange,
        "staff_answer.not_sure": .orange,
    ]

    var body: some View {
        let answers = book.phrases(in: "staff_answer")
            .filter { $0.id != "staff_answer.tap_instruction" }
            .map { book.line($0.id, in: localeCode) }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PhraseLineView(line: question, localFont: .largeTitle)
                Divider()
                if let answer {
                    answerResult(answer)
                } else {
                    PhraseLineView(line: book.line("staff_answer.tap_instruction", in: localeCode),
                                   localFont: .title3)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(answers) { option in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { answer = option }
                            } label: {
                                let tone = Self.tone[option.id] ?? .accentColor
                                PhraseLineView(line: option, localFont: .title3)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                                    .background(tone.opacity(0.12),
                                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(tone.opacity(0.35), lineWidth: 1.5))
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear { FullBrightness.on() }
        .onDisappear { FullBrightness.off() }
    }

    /// Shown to the user after staff tap: the answer in English, large.
    private func answerResult(_ answer: CardLine) -> some View {
        let tone = Self.tone[answer.id] ?? .accentColor
        return VStack(alignment: .leading, spacing: 12) {
            Text("They answered").font(.headline).foregroundStyle(.secondary)
            Text(answer.english)
                .font(.largeTitle.bold())
                .foregroundStyle(tone)
            if answer.local != answer.english {
                Text(answer.local).foregroundStyle(.secondary)
            }
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.answer = nil }
            } label: {
                Label("Ask again", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(tone.opacity(0.12), in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .cardSurface(padding: 20)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
        .sensoryFeedback(.success, trigger: answer.id)
    }
}
