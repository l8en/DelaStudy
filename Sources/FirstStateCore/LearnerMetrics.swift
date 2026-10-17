import Foundation

public struct LearnerStats: Equatable, Sendable {
    public let xp: Int
    public let level: Int
    public let levelProgress: Double
    public let streakDays: Int
    public let completedCourses: Int
}

public struct AwardProgress: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let symbolName: String
    public let current: Int
    public let target: Int
    public var isUnlocked: Bool { current >= target }
    public var fraction: Double { min(1, Double(current) / Double(max(1, target))) }
}

public enum LearnerMetrics {
    public static func stats(content: LearningContent, snapshot: ProgressSnapshot, now: Date = .now, calendar: Calendar = .current) -> LearnerStats {
        let uniqueAttempted = Set(snapshot.attempts.map(\.questionID)).count
        let uniqueCorrect = Set(snapshot.attempts.filter(\.isCorrect).map(\.questionID)).count
        let completedSessions = snapshot.sessions.filter { $0.completedAt != nil }.count
        let xp = uniqueAttempted * 5 + uniqueCorrect * 15 + completedSessions * 10
        let completedCourses = content.courses.filter { course in
            let states = MasteryEngine.progress(content: content, attempts: snapshot.attempts, courseID: course.id)
            return !states.isEmpty && states.allSatisfy { $0.status == .demonstrated }
        }.count
        return LearnerStats(xp: xp, level: xp / 100 + 1, levelProgress: Double(xp % 100) / 100, streakDays: streak(sessions: snapshot.sessions, now: now, calendar: calendar), completedCourses: completedCourses)
    }

    public static func awards(content: LearningContent, snapshot: ProgressSnapshot, now: Date = .now, calendar: Calendar = .current) -> [AwardProgress] {
        let completed = snapshot.sessions.filter { $0.completedAt != nil }
        let correctQuestions = Set(snapshot.attempts.filter(\.isCorrect).map(\.questionID)).count
        let practicedCourses = Set(snapshot.attempts.compactMap { content.course(containing: $0.objectiveID)?.id }).count
        let stats = stats(content: content, snapshot: snapshot, now: now, calendar: calendar)
        let perfectSessions = completed.filter { session in
            let attempts = snapshot.attempts.filter { $0.sessionID == session.id }
            let expected = content.questions(for: session.objectiveID).count
            return expected > 0 && attempts.count == expected && attempts.allSatisfy(\.isCorrect)
        }.count
        return [
            AwardProgress(id: "first-session", title: "First Step", detail: "Complete your first lesson.", symbolName: "figure.walk.motion", current: completed.count, target: 1),
            AwardProgress(id: "perfect-lens", title: "Crystal Clear", detail: "Finish a lesson with every answer correct.", symbolName: "sparkles", current: perfectSessions, target: 1),
            AwardProgress(id: "five-correct", title: "Quick Study", detail: "Answer five different questions correctly.", symbolName: "bolt.fill", current: correctQuestions, target: 5),
            AwardProgress(id: "explorer", title: "Course Explorer", detail: "Practice in two different courses.", symbolName: "safari.fill", current: practicedCourses, target: 2),
            AwardProgress(id: "streak", title: "Three-Day Rhythm", detail: "Study on three consecutive days.", symbolName: "flame.fill", current: stats.streakDays, target: 3),
            AwardProgress(id: "course-complete", title: "Course Complete", detail: "Demonstrate every lesson in a course.", symbolName: "trophy.fill", current: stats.completedCourses, target: 1)
        ]
    }

    private static func streak(sessions: [StudySession], now: Date, calendar: Calendar) -> Int {
        let studyDays = Set(sessions.compactMap(\.completedAt).map { calendar.startOfDay(for: $0) })
        guard !studyDays.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard studyDays.contains(today) || studyDays.contains(yesterday) else { return 0 }
        var cursor = studyDays.contains(today) ? today : yesterday
        var count = 0
        while studyDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
