import Foundation
import Testing
@testable import FirstStateCore

@Suite("Content and answer evaluation")
struct ContentAndStudyTests {
    @Test func bundledContentIsValid() {
        #expect(ContentValidator.validate(AppContent.content).isEmpty)
        #expect(AppContent.content.courses.count == 29)
        #expect(AppContent.content.courses.filter { $0.level == .highSchool }.count == 17)
        #expect(AppContent.content.courses.filter { $0.level == .college }.count == 12)
        #expect(AppContent.content.objectives.count == 36)
        #expect(AppContent.content.questions.count == 72)
        #expect(AppContent.content.lessonMaterials.count == 36)
        #expect(AppContent.content.lessonMaterials.allSatisfy { !$0.notes.isEmpty })
        #expect(AppContent.content.lessonMaterials.filter { $0.video != nil }.count == 12)
    }

    @Test func everyCourseExposesRealCurriculumAndLessonTests() {
        for course in AppContent.content.courses {
            #expect(course.curriculum.url.scheme == "https")
            #expect(!course.curriculum.provider.isEmpty)
            #expect(!course.curriculum.license.isEmpty)
            for objective in AppContent.content.objectives(for: course.id) {
                #expect(AppContent.content.lesson(for: objective.id) != nil)
                #expect(AppContent.content.questions(for: objective.id).count >= 2)
            }
        }
    }

    @Test func validatorRejectsInvalidEmbeddedVideoIdentifier() {
        let source = AppContent.algebraText
        let curriculum = CurriculumReference(title: "Curriculum", provider: "Provider", url: source.url, license: "CC", attribution: "Attribution")
        let objective = LearningObjective(id: "objective", title: "Objective", summary: "Summary", order: 0, prerequisiteIDs: [], source: source)
        let course = Course(id: "course", title: "Course", subtitle: "Subtitle", subject: .mathematics, level: .highSchool, symbolName: "function", estimatedMinutes: 10, objectiveIDs: [objective.id], source: source, curriculum: curriculum)
        let material = LessonMaterial(objectiveID: objective.id, overview: "Overview", keyIdeas: ["Idea"], notes: [.init(title: "Note", body: "Body")], video: .init(title: "Video", channel: "Channel", youtubeID: "not-valid", duration: "1 min"), readingURL: source.url, attribution: "Attribution")
        let issues = ContentValidator.validate(.init(courses: [course], objectives: [objective], questions: [], lessonMaterials: [material]))
        #expect(issues.contains(.invalidYouTubeID(objectiveID: objective.id)))
    }

    @Test func correctAndIncorrectAnswersEvaluate() throws {
        let question = try #require(AppContent.content.question(id: "record-date"))
        #expect(try question.evaluates(choiceID: "b"))
        #expect(try !question.evaluates(choiceID: "a"))
    }

    @Test func invalidAnswerIsRejected() throws {
        let question = try #require(AppContent.content.question(id: "record-date"))
        #expect(throws: LearningError.invalidAnswer(questionID: question.id, choiceID: "missing")) {
            try question.evaluates(choiceID: "missing")
        }
    }

    @Test func questionMapsToExpectedObjective() throws {
        let question = try #require(AppContent.content.question(id: "purpose-request"))
        #expect(question.objectiveID == "purpose-perspective")
        #expect(AppContent.content.objective(id: question.objectiveID)?.title == "Purpose & perspective")
    }

    @Test func attemptRecordsOnceAndCarriesScoringMetadata() throws {
        let question = try #require(AppContent.content.question(id: "record-date"))
        var session = StudySession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, objectiveID: question.objectiveID, startedAt: .distantPast)
        let attemptID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let result = try StudyEngine.submit(question: question, choiceID: "b", session: &session, at: Date(timeIntervalSince1970: 100), attemptID: attemptID)
        #expect(result.attempt.id == attemptID)
        #expect(result.attempt.isCorrect)
        #expect(result.attempt.objectiveID == question.objectiveID)
        #expect(result.attempt.contentVersion == question.contentVersion)
        #expect(session.submittedQuestionIDs == [question.id])
        #expect(throws: LearningError.duplicateSubmission(questionID: question.id)) {
            try StudyEngine.submit(question: question, choiceID: "b", session: &session, at: .now)
        }
    }

    @Test func validatorFindsBrokenReferenceAndCycle() {
        let source = AppContent.archiveWorksheet
        let a = LearningObjective(id: "a", title: "A", summary: "A", order: 0, prerequisiteIDs: ["b"], source: source)
        let b = LearningObjective(id: "b", title: "B", summary: "B", order: 1, prerequisiteIDs: ["a"], source: source)
        let question = PracticeQuestion(id: "q", objectiveID: "missing", prompt: "?", choices: [.init(id: "x", text: "X"), .init(id: "x", text: "Again")], correctChoiceID: "z", explanation: "Explanation", source: source)
        let issues = ContentValidator.validate(.init(objectives: [a, b], questions: [question]))
        #expect(issues.contains { if case .prerequisiteCycle = $0 { true } else { false } })
        #expect(issues.contains(.missingObjective(questionID: "q", objectiveID: "missing")))
        #expect(issues.contains(.duplicateChoiceID(questionID: "q", choiceID: "x")))
        #expect(issues.contains(.invalidCorrectChoice(questionID: "q")))
    }
}
