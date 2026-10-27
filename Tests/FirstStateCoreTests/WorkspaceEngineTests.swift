import Foundation
import Testing
@testable import FirstStateCore

@Suite("Planner, notes and review behavior")
struct WorkspaceEngineTests {
    @Test func latestCorrectAnswerClearsReviewButBookmarkRemains() throws {
        let content = AppContent.content
        let q = try #require(content.questions.first)
        func attempt(_ correct: Bool, _ time: Double) -> Attempt {
            Attempt(questionID: q.id, objectiveID: q.objectiveID, submittedChoiceID: "a", isCorrect: correct, timestamp: Date(timeIntervalSince1970: time), sessionID: UUID(), contentVersion: 1)
        }
        let attempts = [attempt(true, 20), attempt(false, 10)]
        #expect(WorkspaceEngine.reviewQuestions(content: content, attempts: attempts).isEmpty)
        #expect(WorkspaceEngine.reviewQuestions(content: content, attempts: attempts, saved: [q.id]).map(\.id) == [q.id])
        #expect(WorkspaceEngine.reviewQuestions(content: content, attempts: attempts+[attempt(false, 30)]).map(\.id) == [q.id])
    }

    @Test func plannerOrdersDueWorkBeforeInboxAndCompleted() {
        var inbox = PersonalTask(title: "Inbox")
        var due = PersonalTask(title: "Due"); due.dueDate = Date(timeIntervalSince1970: 20)
        inbox.courseID = "algebra-i"; inbox.objectiveID = "algebra-equations"; inbox.estimatedMinutes = 25
        var done = PersonalTask(title: "Done"); done.isComplete = true; done.dueDate = .distantPast
        #expect(WorkspaceEngine.sortedTasks([done, inbox, due]).map(\.title) == ["Due", "Inbox", "Done"])
    }

    @Test func newFieldsRoundTripWithWorkspace() throws {
        var snapshot = ProgressSnapshot()
        var task = PersonalTask(title: "Explain a graph")
        task.courseID = "algebra-i"; task.objectiveID = "algebra-graphs"
        task.dueDate = Date(timeIntervalSince1970: 500); task.estimatedMinutes = 15
        snapshot.workspace.tasks = [task]
        snapshot.workspace.savedCourseIDs = ["algebra-i"]
        snapshot.workspace.savedQuestionIDs = ["record-date"]
        snapshot.workspace.lessonNotes = ["read-record": "My observation"]
        snapshot.workspace.noteDrafts = ["read-record": "An unfinished revision"]
        snapshot.workspace.plannerDraft = "Finish this task title"
        let restored = try JSONDecoder().decode(ProgressSnapshot.self, from: JSONEncoder().encode(snapshot))
        #expect(restored == snapshot)
    }

    @Test func olderSchemaFourWorkspaceDefaultsOptionalAdditions() throws {
        var snapshot = ProgressSnapshot()
        snapshot.workspace.tasks = [PersonalTask(title: "Existing task")]
        let data = try JSONEncoder().encode(snapshot)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var workspace = try #require(json["workspace"] as? [String: Any])
        for key in ["savedCourseIDs", "savedQuestionIDs", "plannerDraft", "noteDrafts"] { workspace.removeValue(forKey: key) }
        json["workspace"] = workspace
        let restored = try JSONDecoder().decode(ProgressSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(restored.workspace.tasks.first?.title == "Existing task")
        #expect(restored.workspace.savedCourseIDs == nil)
        #expect(restored.workspace.noteDrafts == nil)
    }
}
