import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let content = AppContent.content
    private let store: any ProgressStore
    var snapshot: ProgressSnapshot
    var startupError: String?
    var presentedError: String?
    var activeSession: StudySession?
    var activeQuestions: [PracticeQuestion] = []
    var questionIndex = 0
    var selectedChoiceID: String?
    var submission: SubmissionResult?
    var isPracticePresented = false
    var didCompleteSession = false

    init(store: any ProgressStore, initialStoreError: String? = nil) {
        self.store = store
        if let initialStoreError {
            snapshot = ProgressSnapshot()
            startupError = "Local storage is unavailable. \(initialStoreError)"
            return
        }
        let issues = ContentValidator.validate(AppContent.content)
        if !issues.isEmpty {
            snapshot = ProgressSnapshot()
            startupError = "Study content is unavailable. \(issues.map(\.description).joined(separator: " "))"
            return
        }
        do { snapshot = try store.load() }
        catch {
            snapshot = ProgressSnapshot()
            startupError = error.localizedDescription
        }
    }

    var progress: [ObjectiveProgress] { MasteryEngine.progress(content: content, attempts: snapshot.attempts) }
    var selectedCourse: Course { content.course(id: snapshot.profile.selectedCourseID) ?? content.courses[0] }
    var selectedCourseProgress: [ObjectiveProgress] { MasteryEngine.progress(content: content, attempts: snapshot.attempts, courseID: selectedCourse.id) }
    var recommendation: Recommendation? {
        if let selected = MasteryEngine.recommendation(content: content, attempts: snapshot.attempts, courseID: selectedCourse.id) { return selected }
        for course in content.courses where course.id != selectedCourse.id {
            if let next = MasteryEngine.recommendation(content: content, attempts: snapshot.attempts, courseID: course.id) { return next }
        }
        return nil
    }
    var stats: LearnerStats { LearnerMetrics.stats(content: content, snapshot: snapshot) }
    var awards: [AwardProgress] { LearnerMetrics.awards(content: content, snapshot: snapshot) }
    var currentQuestion: PracticeQuestion? { activeQuestions.indices.contains(questionIndex) ? activeQuestions[questionIndex] : nil }
    var completedSessions: [StudySession] { snapshot.sessions.filter { $0.completedAt != nil } }
    var todayStudyMinutes: Int {
        let calendar = Calendar.current
        return completedSessions.compactMap { session -> Int? in
            guard let completedAt = session.completedAt, calendar.isDateInToday(completedAt),
                  let course = content.course(containing: session.objectiveID) else { return nil }
            return max(1, course.estimatedMinutes / max(1, course.objectiveIDs.count))
        }.reduce(0, +)
    }
    var accuracy: Double? {
        guard !snapshot.attempts.isEmpty else { return nil }
        return Double(snapshot.attempts.filter(\.isCorrect).count) / Double(snapshot.attempts.count)
    }

    func progress(for courseID: String) -> [ObjectiveProgress] {
        MasteryEngine.progress(content: content, attempts: snapshot.attempts, courseID: courseID)
    }

    func courseCompletion(_ courseID: String) -> Double {
        let states = progress(for: courseID)
        guard !states.isEmpty else { return 0 }
        return Double(states.filter { $0.status == .demonstrated }.count) / Double(states.count)
    }

    func finishOnboarding(intention: StudyIntention, displayName: String, courseID: String) {
        var updated = snapshot
        updated.studyIntention = intention
        updated.profile.displayName = normalizedName(displayName)
        updated.profile.selectedCourseID = courseID
        updated.hasCompletedOnboarding = true
        commit(updated)
    }

    func selectCourse(_ courseID: String) {
        guard content.course(id: courseID) != nil else { return }
        var updated = snapshot
        updated.profile.selectedCourseID = courseID
        commit(updated)
    }

    func updateProfile(name: String, dailyGoalMinutes: Int) {
        var updated = snapshot
        updated.profile.displayName = normalizedName(name)
        updated.profile.dailyGoalMinutes = min(30, max(5, dailyGoalMinutes))
        commit(updated)
    }

    func startRecommendedSession() {
        if let objective = recommendation?.objective { startSession(objectiveID: objective.id) }
    }

    func startSession(objectiveID: String) {
        guard content.objective(id: objectiveID) != nil else {
            presentedError = LearningError.objectiveNotFound(objectiveID).localizedDescription; return
        }
        let questions = content.questions(for: objectiveID)
        guard !questions.isEmpty else { presentedError = "No practice questions are available for this skill."; return }
        activeQuestions = questions
        activeSession = StudySession(objectiveID: objectiveID, startedAt: .now)
        questionIndex = 0
        selectedChoiceID = nil
        submission = nil
        didCompleteSession = false
        isPracticePresented = true
    }

    func submitCurrentAnswer() {
        guard let question = currentQuestion, let choiceID = selectedChoiceID, var session = activeSession else { return }
        do {
            let result = try StudyEngine.submit(question: question, choiceID: choiceID, session: &session, at: .now)
            var updated = snapshot
            updated.attempts.append(result.attempt)
            if let index = updated.sessions.firstIndex(where: { $0.id == session.id }) { updated.sessions[index] = session }
            else { updated.sessions.append(session) }
            try store.save(updated)
            snapshot = updated
            activeSession = session
            submission = result
        } catch { presentedError = error.localizedDescription }
    }

    func advancePractice() {
        if questionIndex + 1 < activeQuestions.count {
            questionIndex += 1
            selectedChoiceID = nil
            submission = nil
        } else { completeSession() }
    }

    func completeSession() {
        guard var session = activeSession else { return }
        session.completedAt = .now
        var updated = snapshot
        if let index = updated.sessions.firstIndex(where: { $0.id == session.id }) { updated.sessions[index] = session }
        else { updated.sessions.append(session) }
        do {
            try store.save(updated)
            snapshot = updated
            activeSession = session
            didCompleteSession = true
        } catch { presentedError = error.localizedDescription }
    }

    func closePractice() {
        isPracticePresented = false
        activeSession = nil
        activeQuestions = []
        selectedChoiceID = nil
        submission = nil
        didCompleteSession = false
    }

    func resetProgress() {
        do {
            try store.reset()
            snapshot = ProgressSnapshot()
            startupError = nil
        } catch { presentedError = error.localizedDescription }
    }

    func retryLoading() {
        do { snapshot = try store.load(); startupError = nil }
        catch { startupError = error.localizedDescription }
    }

    private func commit(_ updated: ProgressSnapshot) {
        do { try store.save(updated); snapshot = updated }
        catch { presentedError = error.localizedDescription }
    }

    private func normalizedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((trimmed.isEmpty ? "Learner" : trimmed).prefix(24))
    }
}
