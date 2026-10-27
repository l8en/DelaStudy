import SwiftUI

struct PracticeView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            Group {
                if model.didCompleteSession { SessionCompleteView(model: model) }
                else if let question = model.currentQuestion { questionView(question) }
                else { ContentUnavailableView("Practice unavailable", systemImage: "doc.questionmark") }
            }
            .background(LensTheme.paper.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let question = model.currentQuestion, !model.didCompleteSession {
                        Button { model.toggleSavedQuestion(question.id) } label: {
                            Image(systemName: model.snapshot.workspace.savedQuestionIDs?.contains(question.id) == true ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44)
                        }.accessibilityLabel("Bookmark question")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: model.closePractice)
                        .accessibilityHint("Your submitted answers are already saved")
                }
            }
        }
        .interactiveDismissDisabled(model.submission != nil && !model.didCompleteSession)
    }

    private func questionView(_ question: PracticeQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("QUESTION \(model.questionIndex + 1) OF \(model.activeQuestions.count)")
                        .font(LensFont.caption.weight(.bold)).tracking(1.2).foregroundStyle(LensTheme.teal)
                    Spacer()
                    Text(model.content.objective(id: question.objectiveID)?.title ?? "Practice")
                        .font(LensFont.caption.bold()).foregroundStyle(LensTheme.navy)
                }
                ProgressView(value: Double(model.questionIndex + (model.submission == nil ? 0 : 1)), total: Double(model.activeQuestions.count))
                    .tint(LensTheme.teal).accessibilityLabel("Session progress")

                if let context = question.context {
                    Text(context)
                        .font(LensFont.callout).italic().foregroundStyle(LensTheme.navy)
                        .padding(.leading, 14).overlay(alignment: .leading) { Rectangle().fill(LensTheme.gold).frame(width: 2) }
                }
                Text(question.prompt)
                    .font(LensFont.system(.title2, weight: .semibold))
                    .foregroundStyle(LensTheme.navy).lineSpacing(4)

                VStack(spacing: 12) {
                    ForEach(question.choices) { choice in answerChoice(choice, question: question) }
                }

                if let submission = model.submission {
                    FeedbackView(result: submission)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
                    Button(model.questionIndex + 1 == model.activeQuestions.count ? "Finish session" : "Continue", action: model.advancePractice)
                        .buttonStyle(LensPrimaryButtonStyle())
                } else {
                    Button("Check my reasoning", action: model.submitCurrentAnswer)
                        .buttonStyle(LensPrimaryButtonStyle()).disabled(model.selectedChoiceID == nil)
                }
                SourceNote(source: question.source)
            }
            .padding(24)
        }
        .animation(reduceMotion || model.quietFocus ? nil : .easeOut(duration: 0.24), value: model.submission)
    }

    private func answerChoice(_ choice: AnswerChoice, question: PracticeQuestion) -> some View {
        let isSelected = model.selectedChoiceID == choice.id
        let isSubmitted = model.submission != nil
        let isCorrect = isSubmitted && choice.id == question.correctChoiceID
        let isWrongSelection = isSubmitted && isSelected && !isCorrect
        return Button {
            guard !isSubmitted else { return }
            model.selectedChoiceID = choice.id
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : isWrongSelection ? "xmark.circle.fill" : isSelected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(isCorrect ? LensTheme.success : isWrongSelection ? LensTheme.error : isSelected ? LensTheme.teal : LensTheme.slate)
                    .font(LensFont.title3).accessibilityHidden(true)
                Text(choice.text).font(LensFont.body.weight(.medium)).foregroundStyle(LensTheme.navy).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isCorrect ? LensTheme.success : isWrongSelection ? LensTheme.error : isSelected ? LensTheme.teal : LensTheme.border, lineWidth: isSelected || isCorrect ? 2 : 1))
        }
        .buttonStyle(.plain).disabled(isSubmitted)
        .accessibilityLabel("\(choice.text)\(isCorrect ? ", correct answer" : isWrongSelection ? ", your answer, incorrect" : isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct FeedbackView: View {
    let result: SubmissionResult
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AnswerSeal(correct: result.attempt.isCorrect, quiet: reduceMotion).frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 9) {
            Label(result.attempt.isCorrect ? "Correct" : "Not quite", systemImage: result.attempt.isCorrect ? "checkmark" : "arrow.counterclockwise")
                .font(LensFont.headline).foregroundStyle(result.attempt.isCorrect ? LensTheme.success : LensTheme.error)
            Text(result.explanation).font(LensFont.body).foregroundStyle(LensTheme.navy).lineSpacing(3)
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background((result.attempt.isCorrect ? LensTheme.success : LensTheme.error).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSummaryElement)
    }
}

private struct SessionCompleteView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    var sessionAttempts: [Attempt] {
        guard let id = model.activeSession?.id else { return [] }
        return model.snapshot.attempts.filter { $0.sessionID == id }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(LensTheme.blue.opacity(0.65)).frame(width: 96, height: 96)
                Circle().trim(from: 0, to: revealed ? 1 : 0).stroke(LensTheme.navy, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 82, height: 82)
                Image(systemName: "checkmark").font(LensFont.system(size: 34, weight: .heavy)).foregroundStyle(LensTheme.navy)
                    .scaleEffect(revealed || reduceMotion ? 1 : 0.6).opacity(revealed || reduceMotion ? 1 : 0)
            }.accessibilityHidden(true)
            EditorialTitle(eyebrow: "Test complete", title: "Lesson complete.")
            Text("\(sessionAttempts.filter(\.isCorrect).count) of \(sessionAttempts.count) correct")
                .font(LensFont.title3.monospacedDigit()).foregroundStyle(LensTheme.navy)
            if let recommendation = model.recommendation {
                Text("Next: \(recommendation.objective.title)").font(LensFont.headline).foregroundStyle(LensTheme.teal)
            } else {
                Text("Course complete").font(LensFont.headline).foregroundStyle(LensTheme.success)
            }
            Spacer()
            Button("Return home", action: model.closePractice).buttonStyle(LensPrimaryButtonStyle())
        }
        .padding(28)
        .onAppear {
            if reduceMotion || model.quietFocus { revealed = true }
            else { withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { revealed = true } }
        }
    }
}
