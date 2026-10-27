import Foundation
import Testing
@testable import FirstStateCore

@Suite("Bite-sized lessons and course resources")
struct BiteLessonTests {
    @Test func allReadingsHaveThreeCompleteShortTeachingSteps() {
        #expect(StudyCurriculum.readings.count == 417)
        for reading in StudyCurriculum.readings.values {
            let facts = BiteLessons.facts(for: reading)
            #expect(facts.count == 3, "Missing lesson: \(reading.title)")
            #expect(Set(facts.map { ReadingChecks.normalized($0.answer) }).count == 3)
            for fact in facts {
                let words = fact.evidence.split(whereSeparator: \.isWhitespace).count
                #expect(words >= 8 && words <= 65, "Oversized step: \(reading.title)")
                #expect(!fact.evidence.contains("_____"))
                #expect(fact.evidence.range(of: fact.answer, options: .caseInsensitive) != nil)
                #expect(fact.prompt.contains("_____"))
                #expect(!fact.evidence.contains("<" + "math"))
            }
            #expect(ReadingChecks.facts(for: reading) == facts)
        }
    }
    @Test func savedStepClampsAndPreservesPriorRecords() throws {
        let reading = try #require(StudyCurriculum.units(for: "geometry").first?.activities.first?.reading)
        var workspace = LearnerWorkspace()
        workspace.awardedActivityIDs = ["geometry-unit-1-1-read"]
        workspace.readingPositions = [reading.id: 0.63]
        workspace.lessonNotes = ["old": "Keep my note"]
        workspace = BiteLessons.moving(to: 1, reading: reading, workspace: workspace)
        #expect(BiteLessons.step(for: reading, workspace: workspace) == 1)
        let restored = try JSONDecoder().decode(LearnerWorkspace.self, from: JSONEncoder().encode(workspace))
        #expect(restored == workspace)
        #expect(restored.readingPositions?[reading.id] == 0.63)
        #expect(restored.lessonNotes["old"] == "Keep my note")
        #expect(StudyCurriculum.earnedXP(workspace: restored) == 10)
        #expect(BiteLessons.step(for: reading, workspace: BiteLessons.moving(to: 900, reading: reading, workspace: workspace)) == 2)
        #expect(BiteLessons.step(for: reading, workspace: BiteLessons.moving(to: -9, reading: reading, workspace: workspace)) == 0)
    }
    @Test func legacyPracticeKeepsItsQuestionsAndNewPracticeUsesTaughtIdeas() throws {
        let reading = try #require(StudyCurriculum.units(for: "first-state-civics").first?.activities.first?.reading)
        let legacy = try JSONDecoder().decode(ReadingCheckProgress.self, from: Data(#"{"cleared":2,"wrongChecks":1}"#.utf8))
        #expect(legacy.contentVersion == nil && legacy.cleared == 2 && legacy.wrongChecks == 1)
        let original = ReadingChecks.facts(for: reading, version: legacy.contentVersion)
        #expect(original.count >= 3)
        let current = ReadingCheckProgress()
        #expect(current.contentVersion == BiteLessons.version)
        #expect(ReadingChecks.facts(for: reading, version: current.contentVersion) == BiteLessons.facts(for: reading))
        #expect(original != BiteLessons.facts(for: reading))
    }
    @Test func olderWorkspaceStillDecodesWithoutStepPositions() throws {
        let data = try JSONEncoder().encode(LearnerWorkspace())
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "biteStepPositions")
        let restored = try JSONDecoder().decode(LearnerWorkspace.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(restored.biteStepPositions == nil)
        #expect(restored.lessonNotes.isEmpty)
    }
    @Test func resourcesAreCourseSpecificCategorizedUniqueAndHTTPS() {
        let content = AppContent.content
        for course in content.courses {
            let resources = CourseResources.items(for: course, content: content)
            #expect(!resources.isEmpty)
            #expect(Set(resources.map(\.id)).count == resources.count)
            #expect(resources.contains { $0.kind == .frameworks && $0.url == course.curriculum.url })
            let allowedReadings = Set(StudyCurriculum.units(for: course.id).flatMap(\.readingURLs).compactMap { StudyCurriculum.readings[$0.absoluteString]?.id })
            let videos = Set(course.objectiveIDs.compactMap { content.lesson(for: $0)?.video?.youtubeID })
            for resource in resources {
                #expect(resource.url.scheme == "https")
                #expect(!resource.title.isEmpty && !resource.publisher.isEmpty)
                if let id = resource.readingID { #expect(allowedReadings.contains(id)) }
                if let video = resource.video { #expect(resource.kind == .videos && videos.contains(video.youtubeID)) }
            }
        }
    }
    @Test func textbooksDeduplicateAndEmptyVideoCategoriesStayHonest() throws {
        let content = AppContent.content
        let biology = try #require(content.course(id: "ap-biology"))
        let books = CourseResources.items(for: biology, content: content).filter { $0.kind == .textbooks }
        #expect(books.count == 1)
        #expect(books.first?.url.absoluteString == "https://openstax.org/details/books/biology-2e")
        let geometry = try #require(content.course(id: "geometry"))
        #expect(CourseResources.items(for: geometry, content: content).filter { $0.kind == .videos }.isEmpty)
    }
}
