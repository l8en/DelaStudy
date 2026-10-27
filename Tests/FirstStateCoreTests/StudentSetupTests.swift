import Foundation
import Testing
@testable import FirstStateCore

@Suite("Student setup")
struct StudentSetupTests {
    private func draft() -> StudentSetupDraft {
        var draft = StudentSetupDraft()
        draft.year = "11th grade"; draft.aim = .exams; draft.subjects = [CourseSubject.biology.rawValue]
        draft.dailyMinutes = 20; draft.workMinutes = 50; draft.breakMinutes = 10; draft.sound = .brown
        return draft
    }
    @Test func stagesGateRequiredChoices() {
        var draft = StudentSetupDraft()
        #expect(!draft.canContinue && draft.completion == 0)
        draft.year = "12th grade"; #expect(draft.canContinue)
        draft.stage = .aim; #expect(!draft.canContinue)
        draft.aim = .college; #expect(draft.canContinue)
        draft.stage = .subjects; #expect(!draft.canContinue)
        draft.subjects = ["physics"]; #expect(draft.canContinue)
        draft.stage = .school; #expect(draft.canContinue && draft.schoolID == nil)
        draft.stage = .ready; #expect(draft.completion == 1)
    }
    @Test func finishUsesRealCoursesAndPreservesLearning() throws {
        var snapshot = ProgressSnapshot()
        snapshot.profile.displayName = "Mhamed"
        snapshot.workspace.lessonNotes = ["my-lesson": "Keep these notes"]
        snapshot.workspace.materials = [StudyMaterial(title: "Class source", kind: .text, text: "Original material")]
        snapshot.workspace.tasks = [PersonalTask(title: "Existing work")]
        snapshot.workspace.includeSchoolInSummary = true
        let finished = try StudentSetupEngine.finish(draft(), snapshot: snapshot, content: AppContent.content)
        let chosen = try #require(AppContent.content.course(id: finished.profile.selectedCourseID))
        #expect(chosen.subject == .biology && chosen.level == .highSchool)
        #expect(finished.workspace.savedCourseIDs?.contains(chosen.id) == true)
        #expect(finished.profile.displayName == snapshot.profile.displayName)
        #expect(finished.profile.dailyGoalMinutes == 20 && finished.workspace.focusPreferences.workMinutes == 50)
        #expect(finished.workspace.focusPreferences.breakMinutes == 10 && finished.workspace.sound == .brown)
        #expect(finished.workspace.academicYear == "11th grade" && finished.workspace.studyAim == .exams)
        #expect(finished.workspace.lessonNotes == snapshot.workspace.lessonNotes)
        #expect(finished.workspace.materials == snapshot.workspace.materials && finished.workspace.tasks == snapshot.workspace.tasks)
        #expect(finished.attempts == snapshot.attempts && finished.sessions == snapshot.sessions)
        #expect(StudyCurriculum.earnedXP(workspace: finished.workspace) == 0)
        #expect(finished.workspace.studentSetup == nil && finished.workspace.academicSetupComplete == true)
        #expect(!finished.workspace.includeSchoolInSummary && !finished.workspace.focusPreferences.alerts)
    }
    @Test func realRoutesAndOptionalTaskAreIdempotent() throws {
        var draft = draft(); draft.route = .ap; draft.addFirstTask = true
        let candidates = StudentSetupEngine.courses(for: draft, content: AppContent.content)
        #expect(!candidates.isEmpty && candidates.allSatisfy { $0.level == .apPreparation && $0.subject == .biology })
        draft.courseID = candidates.first?.id
        let first = try StudentSetupEngine.finish(draft, snapshot: ProgressSnapshot(), content: AppContent.content)
        let second = try StudentSetupEngine.finish(draft, snapshot: first, content: AppContent.content)
        #expect(second.workspace.tasks.count == 1)
        #expect(second.workspace.tasks.first?.courseID == draft.courseID && second.workspace.tasks.first?.estimatedMinutes == 20)
        draft.route = .college; draft.subjects = ["finance"]
        #expect(StudentSetupEngine.courses(for: draft, content: AppContent.content).allSatisfy { $0.level == .college })
    }
    @Test func incompleteAndCorruptChoicesCannotFinish() {
        #expect(throws: StudentSetupEngine.SetupError.self) { try StudentSetupEngine.finish(StudentSetupDraft(), snapshot: ProgressSnapshot(), content: AppContent.content) }
        var draft = draft(); draft.workMinutes = 0
        #expect(throws: StudentSetupEngine.SetupError.self) { try StudentSetupEngine.finish(draft, snapshot: ProgressSnapshot(), content: AppContent.content) }
        draft.workMinutes = 25; draft.subjects = ["fake-subject"]
        #expect(throws: StudentSetupEngine.SetupError.self) { try StudentSetupEngine.finish(draft, snapshot: ProgressSnapshot(), content: AppContent.content) }
        draft.subjects = ["biology"]; draft.schoolID = "not-a-real-school"
        #expect(throws: StudentSetupEngine.SetupError.self) { try StudentSetupEngine.finish(draft, snapshot: ProgressSnapshot(), content: AppContent.content) }
    }
    @Test func draftSurvivesRelaunchAndOldAccountsDoNotRequireSetup() throws {
        var snapshot = ProgressSnapshot(); var draft = draft(); draft.stage = .rhythm
        snapshot.workspace.studentSetup = draft
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        let restored = try decoder.decode(ProgressSnapshot.self, from: encoder.encode(snapshot))
        #expect(restored.workspace.studentSetup == draft)
        var old = try #require(JSONSerialization.jsonObject(with: encoder.encode(LearnerWorkspace())) as? [String: Any])
        old.removeValue(forKey: "studentSetup"); old.removeValue(forKey: "studyAim")
        let migrated = try decoder.decode(LearnerWorkspace.self, from: JSONSerialization.data(withJSONObject: old))
        #expect(migrated.studentSetup == nil && migrated.studyAim == nil)
    }
    @Test func displayTitlesRemoveNumberPrefixesNotAcademicContent() {
        #expect(StudyTitle.display("02 — Membranes") == "Membranes")
        #expect(StudyTitle.display("2.1 Portuguese Exploration") == "Portuguese Exploration")
        #expect(StudyTitle.display("3 – Systems") == "Systems")
        #expect(StudyTitle.display("x² + 2x — a worked example") == "x² + 2x — a worked example")
        #expect(StudyTitle.display("1984") == "1984")
        #expect(StudyTitle.display("1984 and identity") == "1984 and identity")
        #expect(StudyTitle.display("3 laws of motion") == "3 laws of motion")
        #expect(StudyTitle.display("First State Lens") == "First State Lens")
    }
}
