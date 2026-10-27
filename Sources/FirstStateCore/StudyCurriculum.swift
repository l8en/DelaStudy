import Foundation

public struct StudyReading: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let filename: String
    public let sourceURL: URL
    public let book: String
    public let license: String
    public let licenseURL: URL?
    public let version: String
    public let wordCount: Int
    public let recallPrompts: [String]
    public let selfCheck: String?
}

public struct StudyUnit: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let readingURLs: [URL]
    public var activities: [StudyActivity] {
        readingURLs.enumerated().flatMap { index, url in
            [StudyActivity(id: "\(id)-\(index + 1)-read", readingURL: url, kind: .reading),
             StudyActivity(id: "\(id)-\(index + 1)-recall", readingURL: url, kind: .recall)]
        }
    }
}

public struct StudyActivity: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable { case reading, recall }
    public let id: String
    public let readingURL: URL
    public let kind: Kind
    public var reading: StudyReading? { StudyCurriculum.readings[readingURL.absoluteString] }
    public var title: String { StudyTitle.display(reading?.title ?? "Reading unavailable") }
    public var recallActivity: StudyActivity {
        kind == .recall ? self : StudyActivity(id: String(id.dropLast(5)) + "-recall", readingURL: readingURL, kind: .recall)
    }
}

public enum StudyTitle {
    /// Clean navigation labels, not source text, math, citations, or stable IDs.
    public static func display(_ value: String) -> String {
        value.replacingOccurrences(of: #"^\s*(?:\d{1,3}(?:\.\d+)+[.)]?\s+|\d{1,3}[.)]\s+|\d{1,3}\s*[—–:\-]\s*)"#, with: "", options: .regularExpression)
    }
}

/// Original assessment IDs remain intact. Reading completion is not assessed mastery.
public enum StudyCurriculum {
    private struct Catalog: Decodable, Sendable {
        let retrievedOn: String
        let courses: [String: [StudyUnit]]
        let readings: [String: StudyReading]
    }
    public static var directory: URL? {
        #if SWIFT_PACKAGE
        Bundle.module.url(forResource: "Curriculum", withExtension: nil)
        #else
        Bundle.main.url(forResource: "Curriculum", withExtension: nil)
        #endif
    }
    private static let catalog: Catalog? = {
        guard let url = directory?.appendingPathComponent("catalog.json"), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()
    public static var readings: [String: StudyReading] { catalog?.readings ?? [:] }
    public static func units(for courseID: String) -> [StudyUnit] { catalog?.courses[courseID] ?? [] }
    public static func nextActivity(for courseID: String, workspace: LearnerWorkspace) -> StudyActivity? {
        let activities = units(for: courseID).flatMap(\.activities)
        let completed = workspace.completedActivityIDs ?? []
        if let id = workspace.lastOpenedActivityID, let activity = activities.first(where: { $0.id == id && !completed.contains(id) }) { return activity }
        return activities.first { !completed.contains($0.id) }
    }
    public static let activityIDs: Set<String> = {
        Set((catalog?.courses.values.flatMap { $0.flatMap(\.activities).map(\.id) }) ?? [])
    }()
    public static func completedCount(in units: [StudyUnit], workspace: LearnerWorkspace) -> Int {
        let completed = workspace.completedActivityIDs ?? []
        return units.flatMap(\.activities).filter { completed.contains($0.id) }.count
    }
    /// Historical XP is awarded once, even if a learner reopens or unmarks an activity.
    public static func earnedXP(workspace: LearnerWorkspace) -> Int {
        (workspace.awardedActivityIDs ?? []).intersection(activityIDs).count * 10
    }
}

/// A reading and its practice round are one lesson, not two separate Focus offers.
public enum LessonEntry: Hashable, Sendable {
    case activity(StudyActivity)
    case foundation(String)
    public var key: String {
        switch self {
        case .activity(let activity): "reading:\(activity.reading?.id ?? activity.readingURL.absoluteString)"
        case .foundation(let id): "foundation:\(id)"
        }
    }
    public func wasStarted(in snapshot: ProgressSnapshot) -> Bool {
        if snapshot.workspace.startedLessonKeys?.contains(key) == true { return true }
        switch self {
        case .activity(let activity):
            let recall = activity.recallActivity.id
            let read = String(recall.dropLast(7)) + "-read"
            let pair: Set<String> = [read, recall]
            let workspace = snapshot.workspace
            return !(workspace.completedActivityIDs ?? []).isDisjoint(with: pair)
                || !(workspace.awardedActivityIDs ?? []).isDisjoint(with: pair)
                || workspace.readingChecks?[recall] != nil
                || activity.reading.map { workspace.readingPositions?[$0.id] != nil } == true
        case .foundation(let id):
            return snapshot.attempts.contains { $0.objectiveID == id }
                || snapshot.sessions.contains { $0.objectiveID == id }
                || snapshot.workspace.practice?.session.objectiveID == id
                || snapshot.workspace.lessonNotes[id] != nil
        }
    }
    public func shouldOfferFocus(in snapshot: ProgressSnapshot) -> Bool {
        (snapshot.workspace.offerFocusForLessons ?? true) && snapshot.workspace.focus == nil && !wasStarted(in: snapshot)
    }
    public func recordingStart(in snapshot: ProgressSnapshot) -> ProgressSnapshot {
        var updated = snapshot
        updated.workspace.startedLessonKeys = (updated.workspace.startedLessonKeys ?? []).union([key])
        if case .activity(let activity) = self { updated.workspace.lastOpenedActivityID = activity.id }
        return updated
    }
}

public struct ReadingFact: Codable, Equatable, Sendable {
    public let answer: String
    public let prompt: String
    public let evidence: String
}

public enum ReadingChecks {
    private static let catalog: [String: [ReadingFact]] = {
        guard let url = StudyCurriculum.directory?.appendingPathComponent("reading-checks.json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: [ReadingFact]].self, from: data)) ?? [:]
    }()
    public static func facts(for reading: StudyReading, version: String? = BiteLessons.version) -> [ReadingFact] {
        // A partially completed pre-redesign quiz keeps its original prompts.
        version == BiteLessons.version ? BiteLessons.facts(for: reading) : (catalog[reading.id] ?? [])
    }
    public static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    public static func accepts(_ text: String, answer: String) -> Bool { normalized(text) == normalized(answer) }
    public static func choices(_ facts: [ReadingFact]) -> [String] {
        guard let first = facts.first else { return [] }
        let values = Array(facts.prefix(4).map(\.answer))
        // A stable rotation, not a predictable first-choice answer on every reading.
        let shift = first.answer.utf8.reduce(0) { ($0 + Int($1)) % max(1, values.count) }
        return Array(values.dropFirst(shift)) + Array(values.prefix(shift))
    }
}

public struct ReadingCheckProgress: Codable, Equatable, Sendable {
    public var cleared: Int = 0
    public var wrongChecks: Int = 0
    public var contentVersion: String?
    public init(contentVersion: String? = BiteLessons.version) { self.contentVersion = contentVersion }
}
