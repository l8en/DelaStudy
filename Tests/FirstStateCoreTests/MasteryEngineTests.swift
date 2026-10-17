import Foundation
import Testing
@testable import FirstStateCore

@Suite("Explainable mastery and recommendations")
struct MasteryEngineTests {
    let sessionID = UUID(uuidString: "10000000-0000-0000-0000-000000000000")!

    func attempt(_ index: Int, objective: String, correct: Bool) -> Attempt {
        Attempt(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))!, questionID: "q-\(index)", objectiveID: objective, submittedChoiceID: correct ? "correct" : "wrong", isCorrect: correct, timestamp: Date(timeIntervalSince1970: Double(index)), sessionID: sessionID, contentVersion: 1)
    }

    @Test func emptyHistoryStartsAtFirstObjective() throws {
        let recommendation = try #require(MasteryEngine.recommendation(content: AppContent.content, attempts: [], courseID: "first-state-civics"))
        #expect(recommendation.objective.id == "read-record")
        let progress = MasteryEngine.progress(content: AppContent.content, attempts: [], courseID: "first-state-civics")
        #expect(progress.first?.status == .ready)
        #expect(progress.dropFirst().allSatisfy { $0.status == .locked })
    }

    @Test func masteryNeedsTwoCorrectAnswersAndUnlocksNext() throws {
        let attempts = [attempt(1, objective: "read-record", correct: true), attempt(2, objective: "read-record", correct: true)]
        let progress = MasteryEngine.progress(content: AppContent.content, attempts: attempts, courseID: "first-state-civics")
        let first = try #require(progress.first)
        #expect(first.mastery == 0.75)
        #expect(first.status == .demonstrated)
        #expect(progress[1].status == .ready)
        #expect(MasteryEngine.recommendation(content: AppContent.content, attempts: attempts, courseID: "first-state-civics")?.objective.id == "purpose-perspective")
    }

    @Test func scoreStaysBoundedAcrossManyAttempts() throws {
        let attempts = (1...100).map { attempt($0, objective: "read-record", correct: $0.isMultiple(of: 3)) }
        let result = try #require(MasteryEngine.progress(content: AppContent.content, attempts: attempts, courseID: "first-state-civics").first)
        #expect((0...1).contains(result.mastery))
    }

    @Test func latestIncorrectPrioritizesReviewDeterministically() throws {
        let attempts = [attempt(1, objective: "read-record", correct: true), attempt(2, objective: "read-record", correct: false)]
        let recommendation = try #require(MasteryEngine.recommendation(content: AppContent.content, attempts: attempts, courseID: "first-state-civics"))
        #expect(recommendation.objective.id == "read-record")
        #expect(recommendation.reason.contains("latest answer"))
    }

    @Test func identicalInputsProduceIdenticalRecommendation() {
        let attempts = [attempt(1, objective: "read-record", correct: false)]
        #expect(MasteryEngine.recommendation(content: AppContent.content, attempts: attempts) == MasteryEngine.recommendation(content: AppContent.content, attempts: attempts))
    }
}
