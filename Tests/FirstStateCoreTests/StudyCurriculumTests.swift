import Foundation
import Testing
@testable import FirstStateCore

@Suite("Five-unit study curricula")
struct StudyCurriculumTests {
    @Test func everyReadingHasWorkingChecksAndValidDistractors() throws {
        for reading in StudyCurriculum.readings.values {
            let facts = ReadingChecks.facts(for: reading)
            #expect(facts.count >= 3, "Missing checks: \(reading.filename)")
            #expect(Set(facts.map { ReadingChecks.normalized($0.answer) }).count == facts.count)
            #expect(Set(ReadingChecks.choices(facts)).count >= 3)
            #expect(ReadingChecks.choices(facts).contains(facts[0].answer))
            for fact in facts {
                #expect(fact.prompt.contains("_____"))
                #expect(!fact.evidence.contains("_____"))
                #expect(!fact.answer.isEmpty && fact.evidence.count > fact.answer.count)
                #expect(ReadingChecks.accepts("  \(fact.answer.uppercased()) \n", answer: fact.answer))
                #expect(!ReadingChecks.accepts("not-the-answer", answer: fact.answer))
            }
        }
    }
    @Test func interactiveCheckProgressPersistsAlongsideOldWrittenResponses() throws {
        var workspace = LearnerWorkspace()
        var check = ReadingCheckProgress(); check.cleared = 2; check.wrongChecks = 1
        workspace.readingChecks = ["geometry-unit-1-1-recall": check]
        workspace.activityResponses = ["old-response": "Keep my original notes"]
        let restored = try JSONDecoder().decode(LearnerWorkspace.self, from: JSONEncoder().encode(workspace))
        #expect(restored.readingChecks == workspace.readingChecks)
        #expect(restored.activityResponses == workspace.activityResponses)
    }
    @Test func everyCourseContainsThirtyRealActivitiesInFiveUnits() throws {
        var allIDs: Set<String> = []
        for course in AppContent.content.courses {
            let units = StudyCurriculum.units(for: course.id)
            #expect(units.count >= 5, "Missing units in \(course.id)")
            let activities = units.flatMap(\.activities)
            #expect(activities.count >= 30)
            #expect(Set(units.flatMap(\.readingURLs)).count >= 15, "Duplicate readings within \(course.id)")
            #expect(activities.filter { $0.kind == .reading }.count >= 15)
            #expect(activities.filter { $0.kind == .recall }.count >= 15)
            for unit in units { #expect(unit.activities.count >= 6) }
            for activity in activities {
                #expect(allIDs.insert(activity.id).inserted)
                let reading = try #require(activity.reading, "Missing \(activity.readingURL)")
                #expect(!reading.recallPrompts.isEmpty)
                #expect(reading.wordCount >= 80)
                #expect(reading.sourceURL.scheme == "https")
            }
        }
        #expect(allIDs.count == 1170)
    }

    @Test func everyReadingIsLocalScriptFreeAndAttributed() throws {
        let directory = try #require(StudyCurriculum.directory)
        let imagePattern = try NSRegularExpression(pattern: #"<img[^>]+src="([^"]+)""#)
        var images = 0
        for reading in StudyCurriculum.readings.values {
            #expect(!reading.filename.contains("/"))
            let html = try String(contentsOf: directory.appendingPathComponent(reading.filename), encoding: .utf8)
            #expect(html.contains("<article>"))
            #expect(html.contains("<footer>"))
            #expect(html.contains("name=\"viewport\""))
            #expect(!html.lowercased().contains("<script"))
            #expect(html.count > 700)
            if reading.book != "First State Lens · original instruction" { #expect(reading.licenseURL != nil) }
            let text = html as NSString
            for match in imagePattern.matches(in: html, range: NSRange(location: 0, length: text.length)) {
                let filename = text.substring(with: match.range(at: 1))
                #expect(!filename.contains("/"))
                #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent(filename).path))
                images += 1
            }
        }
        #expect(images > 3000, "Textbook diagrams must not disappear when interactive wrappers are removed")
    }

    @Test func newWorkspaceFieldsRoundTripWithoutChangingLegacyProgress() throws {
        var workspace = LearnerWorkspace()
        workspace.avatarFilename = UUID().uuidString + ".jpg"
        let ids = Set(StudyCurriculum.units(for: "geometry").flatMap(\.activities).prefix(6).map(\.id))
        workspace.completedActivityIDs = ids; workspace.awardedActivityIDs = ids
        workspace.activityResponses = ["geometry-unit-1-1-recall": "Adjacent angles in a linear pair sum to 180 degrees."]
        workspace.showLiveActivity = false
        workspace.readingPositions = ["geometry-1-1": 0.4]
        workspace.focusTaskDraft = "Study angle relationships"
        let restored = try JSONDecoder().decode(LearnerWorkspace.self, from: JSONEncoder().encode(workspace))
        #expect(restored == workspace)
        var snapshot = ProgressSnapshot(); snapshot.workspace = workspace
        let stats = LearnerMetrics.stats(content: AppContent.content, snapshot: snapshot)
        #expect(stats.xp == 60)
        #expect(stats.completedCourses == 0) // Studied is not demonstrated.
        #expect(LearnerMetrics.awards(content: AppContent.content, snapshot: snapshot).first { $0.id == "unit-studies" }?.isUnlocked == true)
    }

    @Test func unmarkingOrRepeatingDoesNotFarmOrRevokeXP() throws {
        var workspace = LearnerWorkspace()
        let unit = try #require(StudyCurriculum.units(for: "geometry").first)
        let id = try #require(unit.activities.first).id
        workspace.awardedActivityIDs = [id, "unknown-activity"]
        workspace.completedActivityIDs = []
        #expect(StudyCurriculum.earnedXP(workspace: workspace) == 10)
        workspace.awardedActivityIDs?.insert(id)
        #expect(StudyCurriculum.earnedXP(workspace: workspace) == 10)
    }

    @Test func oldSchemaFourRecordsDecodeWithoutNewKeys() throws {
        let data = try JSONEncoder().encode(LearnerWorkspace())
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["avatarFilename", "completedActivityIDs", "awardedActivityIDs", "activityResponses", "lastActivityID", "showLiveActivity"] { object.removeValue(forKey: key) }
        let restored = try JSONDecoder().decode(LearnerWorkspace.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(restored.completedActivityIDs == nil)
        #expect(restored.avatarFilename == nil)
        #expect(restored.focusPreferences.workMinutes == 25)
        #expect(StudyCurriculum.earnedXP(workspace: restored) == 0)
    }
    @Test func levelingCrossesOnlyAfterTenUniqueStudyActivities() {
        let ids = StudyCurriculum.units(for: "geometry").flatMap(\.activities).prefix(10).map(\.id)
        var snapshot = ProgressSnapshot()
        snapshot.workspace.awardedActivityIDs = Set(ids.prefix(9))
        #expect(LearnerMetrics.stats(content: AppContent.content, snapshot: snapshot).level == 1)
        snapshot.workspace.awardedActivityIDs = Set(ids)
        let stats = LearnerMetrics.stats(content: AppContent.content, snapshot: snapshot)
        #expect(stats.xp == 100 && stats.level == 2 && stats.levelProgress == 0)
    }
    @Test func readingToRecallPairIsStableAndIdempotent() throws {
        let unit = try #require(StudyCurriculum.units(for: "geometry").first)
        let reading = try #require(unit.activities.first)
        #expect(reading.recallActivity.id == unit.activities[1].id)
        #expect(reading.recallActivity.recallActivity == reading.recallActivity)
        #expect(StudyCurriculum.activityIDs.contains(reading.recallActivity.id))
    }
    @Test func highSchoolFinanceTeachesPersonalRatherThanCorporateFinance() throws {
        let units = StudyCurriculum.units(for: "personal-finance")
        #expect(units.map(\.title) == ["Income and spending", "Saving and future goals", "Credit reports and records", "Everyday borrowing and banking", "College costs and commitments"])
        for readingURL in units.flatMap(\.readingURLs) {
            let reading = try #require(StudyCurriculum.readings[readingURL.absoluteString])
            #expect(reading.sourceURL.host == "www.consumerfinance.gov")
            #expect(reading.selfCheck != nil)
            #expect(reading.book == "First State Lens · original instruction")
        }
    }
}
