import SwiftUI

struct ReadingCheckView: View {
    @Bindable var model: AppModel
    let reading: StudyReading
    let activityID: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var progress = ReadingCheckProgress()
    @State private var selection = ""
    @State private var input = ""
    @State private var matches: [String: String] = [:]
    @State private var pickedTerm: String?
    @State private var feedback: Bool?
    @State private var feedbackTick = 0
    @FocusState private var typing: Bool
    private var facts: [ReadingFact] { ReadingChecks.facts(for: reading, version: progress.contentVersion) }
    private var quiet: Bool { reduceMotion || model.quietFocus }
    private var saved: Bool { model.snapshot.workspace.completedActivityIDs?.contains(activityID) == true }
    private var alreadyEarned: Bool { model.snapshot.workspace.awardedActivityIDs?.contains(activityID) == true }
    private var ready: Bool {
        switch progress.cleared {
        case 0: !selection.isEmpty
        case 1: !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: matches.count == 3
        default: true
        }
    }
    var body: some View {
        Group {
            if facts.count < 3 {
                ContentUnavailableView("Practice couldn’t load", systemImage: "arrow.clockwise", description: Text("Reopen this reading to try again. Your progress is unchanged."))
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        ForEach(0..<3) { i in Capsule().fill(i < progress.cleared ? LensTheme.success : LensTheme.border).frame(height: 5) }
                    }.padding(.horizontal, 22).padding(.vertical, 14).accessibilityLabel("\(min(3, progress.cleared)) of 3 questions complete")
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            if progress.contentVersion == nil && progress.cleared < 3 {
                                DisclosureGroup("Review your earlier practice") {
                                    ForEach(Array(facts.prefix(3).enumerated()), id: \.offset) { _, fact in
                                        Text(fact.evidence).font(LensFont.subheadline).padding(.vertical, 8)
                                    }
                                }.font(LensFont.subheadline)
                            }
                            if progress.cleared >= 3 { summary }
                            else { VStack(alignment: .leading, spacing: 22) { question }.id(progress.cleared).transition(.opacity) }
                        }.padding(22)
                    }.scrollDismissesKeyboard(.interactively)
                    footer
                }
            }
        }.onAppear {
            progress = model.snapshot.workspace.readingChecks?[activityID] ?? ReadingCheckProgress()
            progress.cleared = min(3, max(0, progress.cleared))
        }
        .sensoryFeedback(.success, trigger: feedbackTick) { _, _ in !quiet && feedback == true }
        .animation(quiet ? nil : .spring(response: 0.38, dampingFraction: 0.85), value: feedback)
        .animation(quiet ? nil : .easeOut(duration: 0.18), value: progress.cleared)
    }
    @ViewBuilder private var question: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(StudyTitle.display(reading.title)).font(LensFont.caption.weight(.medium)).foregroundStyle(LensTheme.slate)
            Text(progress.cleared == 0 ? "Choose the missing term." : progress.cleared == 1 ? "Fill in the blank." : "Make the connections.")
                .font(LensFont.system(.title2, weight: .bold)).tracking(-0.5)
        }
        if progress.cleared == 0 {
            Text(facts[0].prompt).font(LensFont.body).lineSpacing(6).fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                ForEach(ReadingChecks.choices(facts), id: \.self) { choice in
                    let correct = feedback == true && choice == facts[0].answer
                    let wrong = feedback == false && selection == choice
                    Button { selection = choice } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selection == choice ? "largecircle.fill.circle" : "circle").foregroundStyle(LensTheme.teal)
                            Text(choice).font(LensFont.body.weight(.semibold)).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }.padding(16).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            .background(correct ? LensTheme.success.opacity(0.10) : wrong ? LensTheme.error.opacity(0.08) : selection == choice ? LensTheme.accentWash : LensTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(correct ? LensTheme.success : wrong ? LensTheme.error : selection == choice ? LensTheme.teal : LensTheme.border, lineWidth: selection == choice ? 2 : 1))
                    }.buttonStyle(LensCardButtonStyle()).disabled(feedback != nil)
                        .accessibilityAddTraits(selection == choice ? .isSelected : []).accessibilityIdentifier("check-choice-\(choice)")
                }
            }
        } else if progress.cleared == 1 {
            Text(facts[1].prompt).font(LensFont.body).lineSpacing(6)
            TextField("Missing term", text: $input, prompt: Text("Type your answer").foregroundStyle(LensTheme.slate))
                .font(LensFont.title3.weight(.medium)).textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding(18).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(feedback == true ? LensTheme.success : feedback == false ? LensTheme.error : typing ? LensTheme.teal : LensTheme.border, lineWidth: 2))
                .focused($typing).submitLabel(.done).onSubmit { if ready { check() } }.disabled(feedback != nil)
                .accessibilityIdentifier("blank-answer")
        } else {
            Text("Drag a term, or tap a term then its blank.").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105))], spacing: 8) {
                ForEach(Array(facts.prefix(3)).reversed(), id: \.answer) { fact in
                    Button { pickedTerm = pickedTerm == fact.answer ? nil : fact.answer } label: {
                        Text(fact.answer).font(LensFont.subheadline.weight(.semibold)).multilineTextAlignment(.center)
                            .padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(pickedTerm == fact.answer ? LensTheme.onInk : LensTheme.teal)
                            .background(pickedTerm == fact.answer ? LensTheme.navy : LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(LensCardButtonStyle()).draggable(fact.answer).disabled(feedback != nil)
                        .accessibilityIdentifier("match-term-\(fact.answer)").accessibilityAddTraits(pickedTerm == fact.answer ? .isSelected : [])
                }
            }
            ForEach(Array(facts.prefix(3).enumerated()), id: \.offset) { index, fact in
                Button {
                    guard feedback == nil else { return }
                    if let term = pickedTerm { assign(term, to: fact.answer); pickedTerm = nil }
                    else { matches.removeValue(forKey: fact.answer) }
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(fact.prompt).font(LensFont.subheadline).lineSpacing(4).multilineTextAlignment(.leading)
                        Text(matches[fact.answer] ?? "Drop term here").font(LensFont.subheadline.weight(.semibold))
                            .foregroundStyle(LensTheme.teal).padding(.vertical, 8).padding(.horizontal, 12)
                            .background(LensTheme.accentWash, in: Capsule())
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(matches[fact.answer] == nil ? LensTheme.border : LensTheme.teal))
                }.buttonStyle(.plain)
                    .dropDestination(for: String.self) { items, _ in
                        guard feedback == nil, let term = items.first, facts.prefix(3).contains(where: { $0.answer == term }) else { return false }
                        assign(term, to: fact.answer); return true
                    }.accessibilityLabel("Blank \(index+1), \(fact.prompt), \(matches[fact.answer] ?? "empty")")
                    .accessibilityIdentifier("match-slot-\(index)")
            }
        }
    }
    private var summary: some View {
        VStack(alignment: .leading, spacing: 18) {
            AnswerSeal(correct: true, quiet: quiet).frame(width: 76, height: 76)
            Text("Lesson complete.").font(LensFont.system(.title, weight: .bold)).tracking(-0.7)
            Text("3 of 3 completed").font(LensFont.title3.weight(.semibold))
            if progress.wrongChecks > 0 { Text("\(progress.wrongChecks) checks revisited").font(LensFont.subheadline).foregroundStyle(LensTheme.slate) }
            if saved { Label("Practice saved", systemImage: "checkmark.circle.fill").font(LensFont.headline).foregroundStyle(LensTheme.success).accessibilityIdentifier("practice-saved") }
            Button("Practice again") {
                let fresh = ReadingCheckProgress()
                if save(fresh) { progress = fresh; resetAnswer() }
            }.font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44)
            if saved {
                Button("Mark as unfinished") {
                    if model.updateWorkspace({ w in
                        w.completedActivityIDs?.remove(activityID)
                        w.readingChecks?[activityID] = ReadingCheckProgress()
                    }) { progress = ReadingCheckProgress(); resetAnswer() }
                }.font(LensFont.caption).frame(minHeight: 44)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let correct = feedback {
                HStack(alignment: .top, spacing: 14) {
                    AnswerSeal(correct: correct, quiet: quiet).frame(width: 38, height: 38)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(correct ? "That’s it." : "Not quite. Try again.").font(LensFont.headline).foregroundStyle(correct ? LensTheme.success : LensTheme.error)
                        Text(correct ? (progress.cleared == 2 ? "All three connections match." : facts[progress.cleared].evidence) : (progress.cleared == 2 ? "You can move a term or tap a filled blank to clear it." : facts[progress.cleared].evidence))
                            .font(LensFont.subheadline).lineSpacing(3)
                    }
                }.accessibilityElement(children: .combine).accessibilityIdentifier(correct ? "answer-correct" : "answer-incorrect")
                    .transition(quiet ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
            Button(progress.cleared >= 3 ? (saved ? "Done" : alreadyEarned ? "Save practice" : "Complete practice · +10 XP") : feedback == true ? "Continue" : feedback == false ? "Try again" : "Check answer") {
                if progress.cleared >= 3 { finish() }
                else if feedback == true { advance() }
                else if feedback == false { feedback = nil }
                else { check() }
            }.buttonStyle(LensPrimaryButtonStyle()).disabled(!ready && feedback == nil).accessibilityIdentifier("check-answer")
                .transaction { $0.animation = nil }
        }.padding(20).background(feedback == nil ? LensTheme.paper : (feedback == true ? LensTheme.success : LensTheme.error).opacity(0.08))
    }
    private func assign(_ term: String, to key: String) {
        matches = matches.filter { $0.value != term }; matches[key] = term
    }
    private func check() {
        guard feedback == nil, ready, facts.count >= 3 else { return }; typing = false
        let correct = progress.cleared == 0 ? selection == facts[0].answer : progress.cleared == 1 ? ReadingChecks.accepts(input, answer: facts[1].answer) : facts.prefix(3).allSatisfy { matches[$0.answer] == $0.answer }
        if !correct {
            var updated = progress; updated.wrongChecks += 1
            guard save(updated) else { return }; progress = updated
        }
        feedback = correct; feedbackTick += 1
    }
    private func advance() {
        var updated = progress; updated.cleared += 1
        guard save(updated) else { return }; progress = updated; resetAnswer()
    }
    private func resetAnswer() { feedback = nil; selection = ""; input = ""; matches = [:]; pickedTerm = nil }
    private func save(_ value: ReadingCheckProgress) -> Bool {
        model.updateWorkspace { w in w.readingChecks = (w.readingChecks ?? [:]).merging([activityID: value]) { _, new in new } }
    }
    private func finish() {
        if saved { dismiss(); return }
        model.updateWorkspace { w in
            w.completedActivityIDs = (w.completedActivityIDs ?? []).union([activityID])
            w.awardedActivityIDs = (w.awardedActivityIDs ?? []).union([activityID])
            w.lastActivityID = activityID
        }
    }
}

struct AnswerSeal: View {
    let correct: Bool
    let quiet: Bool
    @State private var appeared = false
    var body: some View {
        GeometryReader { g in
            let size = min(g.size.width, g.size.height)
            ZStack {
                Circle().fill((correct ? LensTheme.success : LensTheme.error).opacity(0.12))
                Circle().trim(from: 0, to: appeared ? 1 : 0).stroke(correct ? LensTheme.success : LensTheme.error, style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(-90))
                Image(systemName: correct ? "checkmark" : "arrow.counterclockwise").font(LensFont.system(size: size*0.39, weight: .bold))
                    .foregroundStyle(correct ? LensTheme.success : LensTheme.error).scaleEffect(appeared ? 1 : 0.6)
            }.opacity(appeared ? 1 : 0)
        }.onAppear { withAnimation(quiet ? nil : .spring(response: 0.4, dampingFraction: 0.72)) { appeared = true } }.accessibilityHidden(true)
    }
}
