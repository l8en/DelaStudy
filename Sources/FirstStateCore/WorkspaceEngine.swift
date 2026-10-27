import Foundation

public enum WorkspaceEngine {
    /// Only the latest answer determines whether a question needs review.
    public static func reviewQuestions(content: LearningContent, attempts: [Attempt], saved: Set<String> = []) -> [PracticeQuestion] {
        var latest: [String: Attempt] = [:]
        for attempt in attempts {
            if let previous = latest[attempt.questionID], previous.timestamp > attempt.timestamp { continue }
            latest[attempt.questionID] = attempt
        }
        return content.questions.filter { saved.contains($0.id) || latest[$0.id]?.isCorrect == false }
    }

    public static func sortedTasks(_ tasks: [PersonalTask]) -> [PersonalTask] {
        tasks.sorted {
            if $0.isComplete != $1.isComplete { return !$0.isComplete }
            if $0.dueDate != $1.dueDate { return ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
