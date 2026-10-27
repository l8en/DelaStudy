import Foundation

/// Additive local state. Kept separate from the original assessment and profile models.
public struct LearnerWorkspace: Codable, Equatable, Sendable {
    public var schoolID: String?
    public var includeSchoolInSummary = false
    public var interests: Set<String> = []
    public var banner = "mathematics"
    public var featuredAwardIDs: Set<String> = []
    public var weeklyGoal = ""
    public var assessmentDate: Date?
    public var counselorNotes = ""
    public var routes = ""
    public var lessonNotes: [String: String] = [:]
    public var writtenResponses: [String: String] = [:]
    public var rubricChecks: Set<String> = []
    public var readingAnchors: [String: String] = [:]
    public var tasks: [PersonalTask] = []
    public var focusPreferences = FocusPreferences()
    public var focus: FocusSession?
    public var focusHistory: [FocusRecord] = []
    public var favoriteSounds: Set<StudySound> = []
    public var sound: StudySound = .silence
    public var soundLevel: Double = 0.2
    public var stopSoundAtEnd = true
    public var pauseSoundForVideo = true
    public var soundReflection = ""
    public var practice: PracticeDraft?
    // Optional additions preserve schema-4 snapshots from the earlier prototype.
    public var savedCourseIDs: Set<String>? = []
    public var savedQuestionIDs: Set<String>? = []
    public var plannerDraft: String? = ""
    public var noteDrafts: [String: String]? = [:]
    public var avatarFilename: String?
    public var completedActivityIDs: Set<String>? = []
    public var awardedActivityIDs: Set<String>? = []
    public var activityResponses: [String: String]? = [:]
    public var lastActivityID: String?
    public var showLiveActivity: Bool? = true
    public var focusTaskDraft: String?
    public var readingPositions: [String: Double]?
    public var readingChecks: [String: ReadingCheckProgress]?
    public var academicYear: String?
    public var studyRoute: AcademicRoute?
    public var academicSetupComplete: Bool?
    public var materials: [StudyMaterial]?
    public var studentSetup: StudentSetupDraft?
    public var studyAim: StudyAim?
    public var offerFocusForLessons: Bool?
    public var startedLessonKeys: Set<String>?
    public var lastOpenedActivityID: String?
    public var biteStepPositions: [String: Int]?
    public init() {}
}

public struct PracticeDraft: Codable, Equatable, Sendable {
    public var session: StudySession
    public var questionIndex: Int
    public var selectedChoiceID: String?
    public init(session: StudySession, questionIndex: Int, selectedChoiceID: String?) {
        self.session = session; self.questionIndex = questionIndex; self.selectedChoiceID = selectedChoiceID
    }
}

public struct PersonalTask: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var isComplete = false
    public var courseID: String?
    public var objectiveID: String?
    public var dueDate: Date?
    public var estimatedMinutes: Int?
    public init(title: String) { self.title = title }
}

public enum StudySound: String, CaseIterable, Codable, Sendable {
    case silence, white, pink, brown, rain, shoreline, grove
    public var title: String {
        switch self {
        case .silence: "Silence"
        case .white: "White noise"
        case .pink: "Pink noise"
        case .brown: "Brown noise"
        case .rain: "Rain study"
        case .shoreline: "Shoreline"
        case .grove: "Quiet grove"
        }
    }
    public var detail: String {
        switch self {
        case .silence: "No playback"
        case .white: "Even spectral density"
        case .pink: "Less energy at higher frequencies"
        case .brown: "Deep, low-frequency texture"
        case .rain: "A soft, synthesized rainfall"
        case .shoreline: "Slow, synthesized tidal washes"
        case .grove: "Air with distant tonal birds"
        }
    }
}

public struct FocusPreferences: Codable, Equatable, Sendable {
    public var workMinutes = 25
    public var breakMinutes = 5
    public var longBreakMinutes = 15
    public var intervalsBeforeLongBreak = 4
    public var automaticBreak = false
    public var alerts = false
    public var breakAlerts = false
    public var completionSound = false
    public var haptics = false
    public var suppressInAppPrompts = true
    public var enterZen = false
    public var keepAwake = false
    public var showTasks = true
    public var showCurrentTask = true
    public var showWallClock = false
    public var night = false
    public var environment = "observatory"
    public var numeralColor = "paper"
    public var systemFocusGuideSeen = false
    public init() {}
}

public enum FocusPhase: String, Codable, Sendable { case work, shortBreak, longBreak }
public struct FocusPause: Codable, Equatable, Sendable {
    public let startedAt: Date
    public var endedAt: Date?
}
public struct FocusRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let task: String
    public let startedAt: Date
    public let endedAt: Date
    public let focusedSeconds: TimeInterval
    public let pauseCount: Int
    public let pauses: [FocusPause]
    public let completed: Bool
}

/// A deadline is persisted; UI ticks only ask for a projection. No background tick is required.
public struct FocusSession: Codable, Equatable, Sendable {
    public var id = UUID()
    public var task: String
    public var objectiveID: String?
    public var phase: FocusPhase = .work
    public var cycle = 1
    public var startedAt: Date
    public var phaseStartedAt: Date
    public var deadline: Date?
    public var remainingWhenPaused: TimeInterval
    public var duration: TimeInterval
    public var pauseCount = 0
    public var pauseHistory: [FocusPause] = []
    public var accumulatedSeconds: TimeInterval = 0
    public var resumedAt: Date?
    public var awaitingNextPhase = false
    public var recoveryMessage: String?
    /// Freeze the cycle configuration at start; later settings affect the next session.
    public let configuration: FocusPreferences

    public init(task: String, objectiveID: String? = nil, preferences: FocusPreferences, now: Date) {
        self.task = task; self.objectiveID = objectiveID
        self.configuration = preferences
        self.startedAt = now; self.phaseStartedAt = now
        let seconds = Double(min(180, max(1, preferences.workMinutes))) * 60
        self.duration = seconds; self.remainingWhenPaused = seconds
        self.deadline = now.addingTimeInterval(seconds); self.resumedAt = now
    }
    public var isRunning: Bool { deadline != nil }
    public func remaining(at now: Date) -> TimeInterval {
        guard let deadline else { return remainingWhenPaused }
        return min(duration, max(0, deadline.timeIntervalSince(now)))
    }
    public mutating func pause(at now: Date) {
        guard isRunning else { return }
        remainingWhenPaused = remaining(at: now)
        if let resumedAt { accumulatedSeconds += max(0, now.timeIntervalSince(resumedAt)) }
        accumulatedSeconds = min(duration, accumulatedSeconds)
        self.resumedAt = nil; deadline = nil; pauseCount += 1
        pauseHistory.append(FocusPause(startedAt:now,endedAt:nil))
    }
    public mutating func resume(at now: Date) {
        guard !isRunning, !awaitingNextPhase, remainingWhenPaused > 0 else { return }
        if let last=pauseHistory.indices.last, pauseHistory[last].endedAt == nil { pauseHistory[last].endedAt=now }
        resumedAt = now; deadline = now.addingTimeInterval(remainingWhenPaused)
    }
    public func record(at now: Date, completed: Bool) -> FocusRecord? {
        guard phase == .work else { return nil }
        let elapsed = min(duration, accumulatedSeconds + max(0, resumedAt.map { now.timeIntervalSince($0) } ?? 0))
        var pauses=pauseHistory
        if let last=pauses.indices.last, pauses[last].endedAt == nil { pauses[last].endedAt=now }
        return FocusRecord(id: id, task: task, startedAt: phaseStartedAt, endedAt: now, focusedSeconds: elapsed, pauseCount: pauseCount, pauses:pauses, completed: completed)
    }
    /// Settles only one interval. Time away never fabricates a chain of completed work.
    public mutating func settle(at now: Date) -> FocusRecord? {
        guard let deadline, now >= deadline, !awaitingNextPhase else { return nil }
        let result = record(at: deadline, completed: true)
        recoveryMessage = now.timeIntervalSince(deadline) > 60 ? "Your interval ended while you were away. Start the next phase when you are ready." : nil
        remainingWhenPaused = 0; self.deadline = nil; resumedAt = nil; awaitingNextPhase = true
        return result
    }
    public mutating func nextPhase(at now: Date, skipBreak: Bool = false) {
        guard awaitingNextPhase || (skipBreak && phase != .work) else { return }
        if phase == .work && !skipBreak {
            phase = cycle % max(1, configuration.intervalsBeforeLongBreak) == 0 ? .longBreak : .shortBreak
        } else { phase = .work; cycle += 1 }
        duration = Double(max(1, phase == .work ? configuration.workMinutes : phase == .longBreak ? configuration.longBreakMinutes : configuration.breakMinutes)) * 60
        id = UUID(); phaseStartedAt = now; remainingWhenPaused = duration; accumulatedSeconds = 0; pauseCount = 0; pauseHistory=[]
        awaitingNextPhase = false; recoveryMessage = nil; resumedAt = now; deadline = now.addingTimeInterval(duration)
    }
}
