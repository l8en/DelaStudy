import Foundation

public struct SubmissionResult: Equatable, Sendable {
    public let attempt: Attempt
    public let explanation: String
}

public enum StudyEngine {
    public static func submit(question: PracticeQuestion, choiceID: String, session: inout StudySession, at date: Date, attemptID: UUID = UUID()) throws -> SubmissionResult {
        guard !session.submittedQuestionIDs.contains(question.id) else { throw LearningError.duplicateSubmission(questionID: question.id) }
        let isCorrect = try question.evaluates(choiceID: choiceID)
        let attempt = Attempt(id: attemptID, questionID: question.id, objectiveID: question.objectiveID, submittedChoiceID: choiceID, isCorrect: isCorrect, timestamp: date, sessionID: session.id, contentVersion: question.contentVersion)
        session.submittedQuestionIDs.insert(question.id)
        return SubmissionResult(attempt: attempt, explanation: question.explanation)
    }
}
