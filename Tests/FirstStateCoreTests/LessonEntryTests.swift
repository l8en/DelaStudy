import Foundation
import Testing
@testable import FirstStateCore

@Suite("Simple lesson entry")
struct LessonEntryTests {
    @Test func freshLessonOffersOnceAndPracticeSharesItsIdentity() throws {
        let activity = try #require(StudyCurriculum.units(for: "geometry").first?.activities.first)
        let entry = LessonEntry.activity(activity)
        let original = ProgressSnapshot()
        #expect(entry.shouldOfferFocus(in: original))
        let entered = entry.recordingStart(in: original)
        #expect(!entry.shouldOfferFocus(in: entered))
        #expect(!LessonEntry.activity(activity.recallActivity).shouldOfferFocus(in: entered))
        #expect(entered.workspace.lastOpenedActivityID == activity.id)
        #expect(entered.attempts == original.attempts && entered.sessions == original.sessions)
        #expect(StudyCurriculum.earnedXP(workspace: entered.workspace) == 0)
        #expect(entered.workspace.focus == nil)
    }
    @Test func preferenceAndActiveTimerSuppressNewOffers() throws {
        let activity = try #require(StudyCurriculum.units(for: "geometry").first?.activities.first)
        var snapshot = ProgressSnapshot(); snapshot.workspace.offerFocusForLessons = false
        #expect(!LessonEntry.activity(activity).shouldOfferFocus(in: snapshot))
        snapshot.workspace.offerFocusForLessons = true
        #expect(LessonEntry.activity(activity).shouldOfferFocus(in: snapshot))
        snapshot.workspace.focus = FocusSession(task: "Keep this session", preferences: FocusPreferences(), now: .now)
        let entered = LessonEntry.activity(activity).recordingStart(in: snapshot)
        #expect(!LessonEntry.activity(activity).shouldOfferFocus(in: snapshot))
        #expect(entered.workspace.focus == snapshot.workspace.focus)
    }
    @Test func oldStudyEvidenceDoesNotBecomeAFreshLesson() throws {
        let activity = try #require(StudyCurriculum.units(for: "geometry").first?.activities.first)
        var snapshot = ProgressSnapshot()
        snapshot.workspace.completedActivityIDs = [activity.id]
        #expect(!LessonEntry.activity(activity.recallActivity).shouldOfferFocus(in: snapshot))
        snapshot.workspace.completedActivityIDs = []; snapshot.workspace.awardedActivityIDs = [activity.recallActivity.id]
        #expect(!LessonEntry.activity(activity).shouldOfferFocus(in: snapshot))
        snapshot.workspace.awardedActivityIDs = []
        snapshot.workspace.readingPositions = [try #require(activity.reading).id: 0.4]
        #expect(!LessonEntry.activity(activity).shouldOfferFocus(in: snapshot))
        snapshot.workspace.readingPositions = [:]
        snapshot.workspace.readingChecks = [activity.recallActivity.id: ReadingCheckProgress()]
        #expect(!LessonEntry.activity(activity).shouldOfferFocus(in: snapshot))
        snapshot.workspace.lessonNotes = ["read-record": "Existing note"]
        #expect(!LessonEntry.foundation("read-record").shouldOfferFocus(in: snapshot))
        #expect(LessonEntry.foundation("check-provenance").shouldOfferFocus(in: snapshot))
    }
    @Test func continueUsesLastUnfinishedActivityWithinTheRightCourse() throws {
        let activities = StudyCurriculum.units(for: "geometry").flatMap(\.activities)
        var workspace = LearnerWorkspace()
        #expect(StudyCurriculum.nextActivity(for: "geometry", workspace: workspace)?.id == activities.first?.id)
        workspace.lastOpenedActivityID = activities[12].id
        #expect(StudyCurriculum.nextActivity(for: "geometry", workspace: workspace)?.id == activities[12].id)
        workspace.completedActivityIDs = [activities[12].id]
        #expect(StudyCurriculum.nextActivity(for: "geometry", workspace: workspace)?.id == activities.first?.id)
        #expect(StudyCurriculum.nextActivity(for: "algebra-i", workspace: workspace)?.id != activities[12].id)
        workspace.completedActivityIDs = Set(activities.map(\.id))
        #expect(StudyCurriculum.nextActivity(for: "geometry", workspace: workspace) == nil)
    }
    @Test func preferencesAndVisitsAreDurableBackwardsCompatibleAndAccountScoped() throws {
        var snapshot = ProgressSnapshot(); snapshot.workspace.offerFocusForLessons = false
        snapshot = LessonEntry.foundation("read-record").recordingStart(in: snapshot)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = AccountProgressFiles(legacy: FileProgressStore(fileURL: directory.appendingPathComponent("progress.json")))
        let first = UUID(), second = UUID()
        try files.store(for: first).save(snapshot)
        #expect(try files.load(for: first, inheritLegacy: false) == snapshot)
        let empty = try files.load(for: second, inheritLegacy: false)
        #expect(empty.workspace.offerFocusForLessons == nil && empty.workspace.startedLessonKeys == nil)
        #expect(LessonEntry.foundation("read-record").shouldOfferFocus(in: empty))
        var old = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(LearnerWorkspace())) as? [String: Any])
        for key in ["offerFocusForLessons", "startedLessonKeys", "lastOpenedActivityID"] { old.removeValue(forKey: key) }
        let restored = try JSONDecoder().decode(LearnerWorkspace.self, from: JSONSerialization.data(withJSONObject: old))
        #expect(restored.offerFocusForLessons == nil && restored.startedLessonKeys == nil && restored.lastOpenedActivityID == nil)
    }
}
