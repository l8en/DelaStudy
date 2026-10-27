import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let identity = LocalIdentity()
    let content = AppContent.content
    private var store: any ProgressStore
    private let accountFiles: AccountProgressFiles
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
    var focusController: FocusController?
    let focusLiveActivity = FocusLiveActivity()
    var levelUp: Int?
    var openFocus = false
    var pendingFocusAfterLogin = false
    var requiresStudentSetup: Bool { identity.unlocked && snapshot.workspace.studentSetup?.isInitialSetup == true }
    var workspaceAvailable: Bool { identity.unlocked && !requiresStudentSetup }
    var quietFocus: Bool {
        snapshot.workspace.focus != nil && snapshot.workspace.focusPreferences.suppressInAppPrompts
    }

    init(store: FileProgressStore, initialStoreError: String? = nil) {
        self.store = store
        accountFiles = AccountProgressFiles(legacy: store)
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
        do { snapshot = identity.hasAccounts ? ProgressSnapshot() : try store.load() }
        catch {
            snapshot = ProgressSnapshot()
            startupError = error.localizedDescription
        }
    }

    func createAccount(username: String, password: String, courseID: String) async {
        let isNew = identity.recoveryUsername == nil
        await identity.create(username: username, password: password) { name, id, inherit in
            self.activateAccount(id: id, name: name, inheritLegacy: inherit, creating: isNew, courseID: courseID)
        }
    }
    func logIn(username: String, password: String) async {
        await identity.signIn(username: username, password: password) { name, id, inherit in
            self.activateAccount(id: id, name: name, inheritLegacy: inherit, creating: false, courseID: "first-state-civics")
        }
    }
    private func activateAccount(id: UUID, name: String, inheritLegacy: Bool, creating: Bool, courseID: String) -> Bool {
        do {
            var saved = try accountFiles.load(for: id, inheritLegacy: inheritLegacy)
            if !saved.hasCompletedOnboarding {
                saved.profile.selectedCourseID = content.course(id: courseID)?.id ?? content.courses[0].id
                saved.profile.displayName = name
                saved.hasCompletedOnboarding = true
            } else if creating { saved.profile.displayName = name }
            if creating { saved.workspace.studentSetup = StudentSetupDraft(snapshot: saved, initial: true) }
            let target = accountFiles.store(for: id)
            try target.save(saved)
            store = target; snapshot = saved; levelUp = nil
            return true
        } catch {
            presentedError = "This account’s study records couldn’t be opened. Nothing was replaced. Try again."
            return false
        }
    }
    @discardableResult func saveStudentSetup(_ draft: StudentSetupDraft) -> Bool {
        guard identity.unlocked else { return false }
        return updateWorkspace { $0.studentSetup = draft }
    }
    @discardableResult func finishStudentSetup(_ draft: StudentSetupDraft) -> Bool {
        guard identity.unlocked else { return false }
        do { return commit(try StudentSetupEngine.finish(draft, snapshot: snapshot, content: content)) }
        catch { presentedError = error.localizedDescription; return false }
    }
    func signOut() {
        do {
            var saved = snapshot
            if let session = activeSession, !didCompleteSession {
                saved.workspace.practice = PracticeDraft(session: session, questionIndex: questionIndex, selectedChoiceID: selectedChoiceID)
            }
            if var session = saved.workspace.focus, session.isRunning {
                session.pause(at: focusController?.now ?? .now); saved.workspace.focus = session
            }
            try store.save(saved)
            focusController?.cancelAlert(); focusController?.audio.stop()
            focusController?.liveActivity.sync(session: nil, enabled: false)
            focusController = nil
            activeSession = nil; activeQuestions = []; selectedChoiceID = nil; submission = nil
            isPracticePresented = false; didCompleteSession = false; openFocus = false; pendingFocusAfterLogin = false; levelUp = nil
            identity.signOut()
            snapshot = ProgressSnapshot()
            store = accountFiles.legacy
        } catch { presentedError = "Your work couldn’t be saved. Try again before signing out." }
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
        guard let day=calendar.dateInterval(of:.day,for:.now) else { return 0 }
        let seconds=snapshot.workspace.focusHistory.reduce(0.0) { total,record in
            let start=max(day.start,record.startedAt),end=min(day.end,record.endedAt)
            guard end>start else { return total }
            let paused=record.pauses.reduce(0.0) { sum,pause in
                sum+max(0,min(end,pause.endedAt ?? record.endedAt).timeIntervalSince(max(start,pause.startedAt)))
            }
            return total+min(record.focusedSeconds,max(0,end.timeIntervalSince(start)-paused))
        }
        return Int(seconds/60)
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

    @discardableResult
    func finishOnboarding(intention: StudyIntention, displayName: String, courseID: String) -> Bool {
        var updated = snapshot
        updated.studyIntention = intention
        updated.profile.displayName = normalizedName(displayName)
        updated.profile.selectedCourseID = courseID
        updated.hasCompletedOnboarding = true
        return commit(updated)
    }

    func selectCourse(_ courseID: String) {
        guard content.course(id: courseID) != nil else { return }
        var updated = snapshot
        updated.profile.selectedCourseID = courseID
        commit(updated)
    }

    @discardableResult
    func updateProfile(name: String, dailyGoalMinutes: Int, banner: String? = nil) -> Bool {
        var updated = snapshot
        updated.profile.displayName = normalizedName(name)
        updated.profile.dailyGoalMinutes = min(30, max(5, dailyGoalMinutes))
        if let banner { updated.workspace.banner = banner }
        return commit(updated)
    }

    func saveCommunityResponse(_ response: String, for promptID: String) {
        var updated = snapshot
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { updated.communityResponses.removeValue(forKey: promptID) }
        else { updated.communityResponses[promptID] = String(trimmed.prefix(600)) }
        commit(updated)
    }

    func toggleChallenge(_ id: String) {
        var updated = snapshot
        if updated.joinedChallengeIDs.contains(id) { updated.joinedChallengeIDs.remove(id) }
        else { updated.joinedChallengeIDs.insert(id) }
        commit(updated)
    }

    func toggleCollegeChecklistItem(_ id: String) {
        var updated = snapshot
        if updated.collegeChecklistIDs.contains(id) { updated.collegeChecklistIDs.remove(id) }
        else { updated.collegeChecklistIDs.insert(id) }
        commit(updated)
    }

    func startRecommendedSession() {
        if let objective = recommendation?.objective { startSession(objectiveID: objective.id) }
    }

    /// Persist the visit before offering Focus, so returning never becomes a prompt loop.
    func enterLesson(_ entry: LessonEntry, courseID: String) -> Bool {
        guard workspaceAvailable, content.course(id: courseID) != nil else { return false }
        let offer = entry.shouldOfferFocus(in: snapshot)
        var updated = entry.recordingStart(in: snapshot)
        updated.profile.selectedCourseID = courseID
        guard updated == snapshot || commit(updated) else { return false }
        return offer
    }

    func startSession(objectiveID: String) {
        guard content.objective(id: objectiveID) != nil else {
            presentedError = LearningError.objectiveNotFound(objectiveID).localizedDescription; return
        }
        let questions = content.questions(for: objectiveID)
        guard !questions.isEmpty else { presentedError = "No practice questions are available for this skill."; return }
        activeQuestions = questions
        let draft = snapshot.workspace.practice
        let recovering = draft?.session.objectiveID == objectiveID && draft?.session.completedAt == nil
        activeSession = recovering ? draft?.session : StudySession(objectiveID: objectiveID, startedAt: .now)
        questionIndex = recovering ? min(draft?.questionIndex ?? 0, questions.count - 1) : 0
        selectedChoiceID = recovering ? draft?.selectedChoiceID : nil
        submission = nil
        if let q = currentQuestion, let session = activeSession,
           let attempt = snapshot.attempts.last(where: { $0.sessionID == session.id && $0.questionID == q.id }) {
            selectedChoiceID = attempt.submittedChoiceID
            submission = SubmissionResult(attempt: attempt, explanation: q.explanation)
        }
        didCompleteSession = false
        persistPractice()
        isPracticePresented = true
    }

    func submitCurrentAnswer() {
        guard submission == nil, let question = currentQuestion, let choiceID = selectedChoiceID, var session = activeSession else { return }
        do {
            let result = try StudyEngine.submit(question: question, choiceID: choiceID, session: &session, at: .now)
            var updated = snapshot
            updated.attempts.append(result.attempt)
            if let index = updated.sessions.firstIndex(where: { $0.id == session.id }) { updated.sessions[index] = session }
            else { updated.sessions.append(session) }
            updated.workspace.practice = PracticeDraft(session: session, questionIndex: questionIndex, selectedChoiceID: choiceID)
            try store.save(updated)
            snapshot = updated
            activeSession = session
            submission = result
        } catch { presentedError = error.localizedDescription }
    }

    func advancePractice() {
        guard submission != nil, !didCompleteSession else { return }
        if questionIndex + 1 < activeQuestions.count {
            questionIndex += 1
            selectedChoiceID = nil
            submission = nil
            persistPractice()
        } else { completeSession() }
    }

    func completeSession() {
        guard var session = activeSession, session.completedAt == nil, !didCompleteSession else { return }
        session.completedAt = .now
        var updated = snapshot
        if let index = updated.sessions.firstIndex(where: { $0.id == session.id }) { updated.sessions[index] = session }
        else { updated.sessions.append(session) }
        updated.workspace.practice = nil
        do {
            try store.save(updated)
            snapshot = updated
            activeSession = session
            didCompleteSession = true
        } catch { presentedError = error.localizedDescription }
    }

    func closePractice() {
        if !didCompleteSession { persistPractice() }
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
            focusController?.cancelAlert()
            focusController?.audio.stop()
            focusController?.liveActivity.sync(session: nil, enabled: false)
            AvatarFiles.remove(snapshot.workspace.avatarFilename)
            snapshot = ProgressSnapshot()
            if let username = identity.username {
                snapshot.profile.displayName = username
                snapshot.hasCompletedOnboarding = true
                try store.save(snapshot)
            }
            startupError = nil
        } catch { presentedError = error.localizedDescription }
    }

    func retryLoading() {
        do { snapshot = try store.load(); startupError = nil }
        catch { startupError = error.localizedDescription }
    }

    @discardableResult
    private func commit(_ updated: ProgressSnapshot) -> Bool {
        let testing = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        guard identity.unlocked || (testing && identity.accountID == nil &&
            (ProcessInfo.processInfo.arguments.contains("--seed-level") || ProcessInfo.processInfo.arguments.contains("--short-focus"))) else { return false }
        do {
            let oldLevel = stats.level
            try store.save(updated); snapshot = updated
            if stats.level > oldLevel && !quietFocus {
                let earned = stats.level
                levelUp = earned
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    if levelUp == earned { levelUp = nil }
                }
            }
            return true
        }
        catch { presentedError = "Your change could not be saved. Try again before leaving this screen."; return false }
    }

    private func normalizedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((trimmed.isEmpty ? "Learner" : trimmed).prefix(24))
    }

    func persistPractice() {
        guard let session = activeSession, !didCompleteSession else { return }
        var updated = snapshot
        updated.workspace.practice = PracticeDraft(session: session, questionIndex: questionIndex, selectedChoiceID: selectedChoiceID)
        commit(updated)
    }

    @discardableResult
    func updateWorkspace(_ change: (inout LearnerWorkspace) -> Void) -> Bool {
        var updated = snapshot
        change(&updated.workspace)
        return commit(updated)
    }

    func learningSummary(includeSchool: Bool) -> String {
        var lines = ["First State Lens · learning record", snapshot.profile.displayName,
                     "\(completedSessions.count) practice sessions · \(progress.filter { $0.status == .demonstrated }.count) demonstrated skills",
                     "These are in-app practice results, not school grades."]
        if includeSchool, let school = SchoolDirectory.schools.first(where: { $0.id == snapshot.workspace.schoolID }) { lines.append("School (self-selected): \(school.name)") }
        for course in content.courses {
            let n = progress(for: course.id).filter { $0.status == .demonstrated }.count
            if n > 0 { lines.append("\(course.title): \(n)/\(course.objectiveIDs.count) skills demonstrated") }
        }
        return lines.joined(separator: "\n")
    }
}
