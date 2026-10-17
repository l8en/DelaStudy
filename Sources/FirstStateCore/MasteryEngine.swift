import Foundation

public enum ObjectiveStatus: String, Codable, Sendable {
    case locked, ready, learning, review, demonstrated
}

public struct ObjectiveProgress: Equatable, Sendable {
    public let objective: LearningObjective
    public let status: ObjectiveStatus
    public let mastery: Double
    public let correctCount: Int
    public let attemptCount: Int

    public var accuracy: Double? { attemptCount == 0 ? nil : Double(correctCount) / Double(attemptCount) }
}

public struct Recommendation: Equatable, Sendable {
    public let objective: LearningObjective
    public let reason: String
}

public enum MasteryEngine {
    public static func progress(content: LearningContent, attempts: [Attempt]) -> [ObjectiveProgress] {
        let ordered = content.objectives.sorted { ($0.order, $0.id) < ($1.order, $1.id) }
        var results: [ObjectiveProgress] = []
        for objective in ordered {
            let relevant = attempts
                .filter { $0.objectiveID == objective.id }
                .sorted { ($0.timestamp, $0.id.uuidString) < ($1.timestamp, $1.id.uuidString) }
            var score = 0.0
            for attempt in relevant {
                score = attempt.isCorrect ? score + (1 - score) * 0.5 : score * 0.65
            }
            score = min(1, max(0, score))
            let correct = relevant.filter(\.isCorrect).count
            let prerequisitesMet = objective.prerequisiteIDs.allSatisfy { requiredID in
                results.first(where: { $0.objective.id == requiredID })?.status == .demonstrated
            }
            let status: ObjectiveStatus
            if !prerequisitesMet { status = .locked }
            else if correct >= 2 && score >= 0.70 { status = .demonstrated }
            else if relevant.last?.isCorrect == false { status = .review }
            else if relevant.isEmpty { status = .ready }
            else { status = .learning }
            results.append(ObjectiveProgress(objective: objective, status: status, mastery: score, correctCount: correct, attemptCount: relevant.count))
        }
        return results
    }

    public static func recommendation(content: LearningContent, attempts: [Attempt]) -> Recommendation? {
        recommendation(content: content, attempts: attempts, courseID: nil)
    }

    public static func progress(content: LearningContent, attempts: [Attempt], courseID: String) -> [ObjectiveProgress] {
        guard let course = content.course(id: courseID) else { return [] }
        let allowed = Set(course.objectiveIDs)
        return progress(content: content, attempts: attempts).filter { allowed.contains($0.objective.id) }
    }

    public static func recommendation(content: LearningContent, attempts: [Attempt], courseID: String?) -> Recommendation? {
        let allowed = courseID.flatMap { content.course(id: $0) }.map { Set($0.objectiveIDs) }
        let candidates = progress(content: content, attempts: attempts).filter {
            $0.status != .locked && $0.status != .demonstrated && (allowed?.contains($0.objective.id) ?? true)
        }
        let priority: [ObjectiveStatus: Int] = [.review: 0, .learning: 1, .ready: 2]
        guard let next = candidates.sorted(by: {
            let left = (priority[$0.status, default: 9], $0.mastery, $0.objective.order, $0.objective.id)
            let right = (priority[$1.status, default: 9], $1.mastery, $1.objective.order, $1.objective.id)
            return left < right
        }).first else { return nil }
        let reason: String
        switch next.status {
        case .review: reason = "Your latest answer here needs another look. A short review can reinforce the key idea."
        case .learning: reason = "You have started this lesson. Continue while the explanation and your reasoning are still fresh."
        case .ready: reason = next.objective.prerequisiteIDs.isEmpty ? "This is the first available lesson in the course." : "Its prerequisite is demonstrated, so this is the next unlocked step."
        default: reason = "This is the next available lesson."
        }
        return Recommendation(objective: next.objective, reason: reason)
    }
}
