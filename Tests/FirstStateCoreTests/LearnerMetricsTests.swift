import Foundation
import Testing
@testable import FirstStateCore

@Suite("Learner rewards")
struct LearnerMetricsTests {
    @Test func xpCountsUniqueWorkAndCompletedLessons() {
        let sessionID = UUID()
        let attempts = [
            Attempt(questionID: "record-date", objectiveID: "read-record", submittedChoiceID: "b", isCorrect: true, timestamp: .now, sessionID: sessionID, contentVersion: 1),
            Attempt(questionID: "record-date", objectiveID: "read-record", submittedChoiceID: "b", isCorrect: true, timestamp: .now, sessionID: sessionID, contentVersion: 1)
        ]
        let session = StudySession(id: sessionID, objectiveID: "read-record", startedAt: .now, completedAt: .now)
        let stats = LearnerMetrics.stats(content: AppContent.content, snapshot: ProgressSnapshot(attempts: attempts, sessions: [session]))
        #expect(stats.xp == 30)
        #expect(stats.level == 1)
        #expect(stats.levelProgress == 0.3)
    }

    @Test func streakCountsConsecutiveCalendarDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let today = calendar.startOfDay(for: now)
        let sessions = (0..<3).map { offset in
            StudySession(objectiveID: "read-record", startedAt: today, completedAt: calendar.date(byAdding: .day, value: -offset, to: today))
        }
        let stats = LearnerMetrics.stats(content: AppContent.content, snapshot: ProgressSnapshot(sessions: sessions), now: now, calendar: calendar)
        #expect(stats.streakDays == 3)
        #expect(LearnerMetrics.awards(content: AppContent.content, snapshot: ProgressSnapshot(sessions: sessions), now: now, calendar: calendar).first { $0.id == "streak" }?.isUnlocked == true)
    }

    @Test func courseExplorerUsesRealAttemptedCourses() {
        let attempts = [
            Attempt(questionID: "record-date", objectiveID: "read-record", submittedChoiceID: "b", isCorrect: true, timestamp: .now, sessionID: UUID(), contentVersion: 1),
            Attempt(questionID: "algebra-balance", objectiveID: "algebra-equations", submittedChoiceID: "a", isCorrect: true, timestamp: .now, sessionID: UUID(), contentVersion: 1)
        ]
        let award = LearnerMetrics.awards(content: AppContent.content, snapshot: ProgressSnapshot(attempts: attempts)).first { $0.id == "explorer" }
        #expect(award?.isUnlocked == true)
    }
}
