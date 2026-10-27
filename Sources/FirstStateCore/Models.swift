import Foundation

public struct SourceReference: Codable, Hashable, Sendable {
    public let title: String
    public let publisher: String
    public let url: URL
    public let accessedOn: Date

    public init(title: String, publisher: String, url: URL, accessedOn: Date) {
        self.title = title
        self.publisher = publisher
        self.url = url
        self.accessedOn = accessedOn
    }
}

public struct LearningObjective: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let order: Int
    public let prerequisiteIDs: [String]
    public let source: SourceReference

    public init(id: String, title: String, summary: String, order: Int, prerequisiteIDs: [String], source: SourceReference) {
        self.id = id
        self.title = title
        self.summary = summary
        self.order = order
        self.prerequisiteIDs = prerequisiteIDs
        self.source = source
    }
}

public enum CourseSubject: String, Codable, CaseIterable, Sendable {
    case history, mathematics, biology, chemistry, physics, english, socialScience, computerScience, finance

    public var title: String {
        switch self {
        case .history: "History"
        case .mathematics: "Mathematics"
        case .biology: "Biology"
        case .chemistry: "Chemistry"
        case .physics: "Physics"
        case .english: "English"
        case .socialScience: "Social Science"
        case .computerScience: "Computer Science"
        case .finance: "Financial Literacy"
        }
    }
}

public enum CourseLevel: String, Codable, CaseIterable, Sendable {
    case highSchool
    case college
    case apPreparation

    public var title: String {
        switch self {
        case .highSchool: "High School"
        case .college: "College"
        case .apPreparation: "AP preparation"
        }
    }
}

public struct CurriculumReference: Codable, Hashable, Sendable {
    public let title: String
    public let provider: String
    public let url: URL
    public let license: String
    public let attribution: String

    public init(title: String, provider: String, url: URL, license: String, attribution: String) {
        self.title = title
        self.provider = provider
        self.url = url
        self.license = license
        self.attribution = attribution
    }
}

public struct Course: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let subject: CourseSubject
    public let level: CourseLevel
    public let symbolName: String
    public let estimatedMinutes: Int
    public let objectiveIDs: [String]
    public let source: SourceReference
    public let curriculum: CurriculumReference

    public init(id: String, title: String, subtitle: String, subject: CourseSubject, level: CourseLevel, symbolName: String, estimatedMinutes: Int, objectiveIDs: [String], source: SourceReference, curriculum: CurriculumReference) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.subject = subject
        self.level = level
        self.symbolName = symbolName
        self.estimatedMinutes = estimatedMinutes
        self.objectiveIDs = objectiveIDs
        self.source = source
        self.curriculum = curriculum
    }
}

public struct LessonVideo: Codable, Hashable, Sendable {
    public let title: String
    public let channel: String
    public let youtubeID: String
    public let duration: String

    public init(title: String, channel: String, youtubeID: String, duration: String) {
        self.title = title
        self.channel = channel
        self.youtubeID = youtubeID
        self.duration = duration
    }

    public var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(youtubeID)")! }
}

public struct NoteSection: Codable, Hashable, Sendable {
    public let title: String
    public let body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

public struct LessonMaterial: Identifiable, Codable, Hashable, Sendable {
    public var id: String { objectiveID }
    public let objectiveID: String
    public let overview: String
    public let keyIdeas: [String]
    public let notes: [NoteSection]
    public let video: LessonVideo?
    public let readingURL: URL
    public let attribution: String

    public init(objectiveID: String, overview: String, keyIdeas: [String], notes: [NoteSection], video: LessonVideo?, readingURL: URL, attribution: String) {
        self.objectiveID = objectiveID
        self.overview = overview
        self.keyIdeas = keyIdeas
        self.notes = notes
        self.video = video
        self.readingURL = readingURL
        self.attribution = attribution
    }
}

public struct AnswerChoice: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

public struct PracticeQuestion: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let objectiveID: String
    public let prompt: String
    public let context: String?
    public let choices: [AnswerChoice]
    public let correctChoiceID: String
    public let explanation: String
    public let source: SourceReference
    public let contentVersion: Int

    public init(id: String, objectiveID: String, prompt: String, context: String? = nil, choices: [AnswerChoice], correctChoiceID: String, explanation: String, source: SourceReference, contentVersion: Int = 1) {
        self.id = id
        self.objectiveID = objectiveID
        self.prompt = prompt
        self.context = context
        self.choices = choices
        self.correctChoiceID = correctChoiceID
        self.explanation = explanation
        self.source = source
        self.contentVersion = contentVersion
    }

    public func evaluates(choiceID: String) throws -> Bool {
        guard choices.contains(where: { $0.id == choiceID }) else {
            throw LearningError.invalidAnswer(questionID: id, choiceID: choiceID)
        }
        return choiceID == correctChoiceID
    }
}

public struct Attempt: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let questionID: String
    public let objectiveID: String
    public let submittedChoiceID: String
    public let isCorrect: Bool
    public let timestamp: Date
    public let sessionID: UUID
    public let contentVersion: Int

    public init(id: UUID = UUID(), questionID: String, objectiveID: String, submittedChoiceID: String, isCorrect: Bool, timestamp: Date, sessionID: UUID, contentVersion: Int) {
        self.id = id
        self.questionID = questionID
        self.objectiveID = objectiveID
        self.submittedChoiceID = submittedChoiceID
        self.isCorrect = isCorrect
        self.timestamp = timestamp
        self.sessionID = sessionID
        self.contentVersion = contentVersion
    }
}

public struct StudySession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let objectiveID: String
    public let startedAt: Date
    public var completedAt: Date?
    public var submittedQuestionIDs: Set<String>

    public init(id: UUID = UUID(), objectiveID: String, startedAt: Date, completedAt: Date? = nil, submittedQuestionIDs: Set<String> = []) {
        self.id = id
        self.objectiveID = objectiveID
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.submittedQuestionIDs = submittedQuestionIDs
    }
}

public struct ProgressSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 4

    public var schemaVersion: Int
    public var hasCompletedOnboarding: Bool
    public var studyIntention: StudyIntention
    public var attempts: [Attempt]
    public var sessions: [StudySession]
    public var profile: LearnerProfile
    public var communityResponses: [String: String]
    public var joinedChallengeIDs: Set<String>
    public var collegeChecklistIDs: Set<String>
    public var workspace = LearnerWorkspace()

    public init(schemaVersion: Int = currentSchemaVersion, hasCompletedOnboarding: Bool = false, studyIntention: StudyIntention = .buildEvidenceSkills, attempts: [Attempt] = [], sessions: [StudySession] = [], profile: LearnerProfile = LearnerProfile(), communityResponses: [String: String] = [:], joinedChallengeIDs: Set<String> = [], collegeChecklistIDs: Set<String> = []) {
        self.schemaVersion = schemaVersion
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.studyIntention = studyIntention
        self.attempts = attempts
        self.sessions = sessions
        self.profile = profile
        self.communityResponses = communityResponses
        self.joinedChallengeIDs = joinedChallengeIDs
        self.collegeChecklistIDs = collegeChecklistIDs
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, hasCompletedOnboarding, studyIntention, attempts, sessions, profile
        case communityResponses, joinedChallengeIDs, collegeChecklistIDs, workspace
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let storedVersion = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard storedVersion <= Self.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(forKey: .schemaVersion, in: values, debugDescription: "Progress was created by a newer app version.")
        }
        schemaVersion = Self.currentSchemaVersion
        hasCompletedOnboarding = try values.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        studyIntention = try values.decodeIfPresent(StudyIntention.self, forKey: .studyIntention) ?? .buildEvidenceSkills
        attempts = try values.decodeIfPresent([Attempt].self, forKey: .attempts) ?? []
        sessions = try values.decodeIfPresent([StudySession].self, forKey: .sessions) ?? []
        profile = try values.decodeIfPresent(LearnerProfile.self, forKey: .profile) ?? LearnerProfile()
        communityResponses = try values.decodeIfPresent([String: String].self, forKey: .communityResponses) ?? [:]
        joinedChallengeIDs = try values.decodeIfPresent(Set<String>.self, forKey: .joinedChallengeIDs) ?? []
        collegeChecklistIDs = try values.decodeIfPresent(Set<String>.self, forKey: .collegeChecklistIDs) ?? []
        workspace = try values.decodeIfPresent(LearnerWorkspace.self, forKey: .workspace) ?? LearnerWorkspace()
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try values.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try values.encode(studyIntention, forKey: .studyIntention)
        try values.encode(attempts, forKey: .attempts)
        try values.encode(sessions, forKey: .sessions)
        try values.encode(profile, forKey: .profile)
        try values.encode(communityResponses, forKey: .communityResponses)
        try values.encode(joinedChallengeIDs, forKey: .joinedChallengeIDs)
        try values.encode(collegeChecklistIDs, forKey: .collegeChecklistIDs)
        try values.encode(workspace, forKey: .workspace)
    }
}

public struct LearnerProfile: Codable, Equatable, Sendable {
    public var displayName: String
    public var dailyGoalMinutes: Int
    public var selectedCourseID: String

    public init(displayName: String = "Learner", dailyGoalMinutes: Int = 10, selectedCourseID: String = "first-state-civics") {
        self.displayName = displayName
        self.dailyGoalMinutes = dailyGoalMinutes
        self.selectedCourseID = selectedCourseID
    }
}

public enum StudyIntention: String, Codable, CaseIterable, Sendable {
    case buildEvidenceSkills
    case prepareForDiscussion
    case understandDelaware

    public var title: String {
        switch self {
        case .buildEvidenceSkills: "Build evidence skills"
        case .prepareForDiscussion: "Prepare for discussion"
        case .understandDelaware: "Understand Delaware's role"
        }
    }
}

public enum LearningError: Error, Equatable, LocalizedError, Sendable {
    case invalidAnswer(questionID: String, choiceID: String)
    case duplicateSubmission(questionID: String)
    case questionNotFound(String)
    case objectiveNotFound(String)
    case persistence(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidAnswer(_, choiceID): "The selected answer “\(choiceID)” is not valid for this question."
        case let .duplicateSubmission(questionID): "Question \(questionID) was already submitted in this session."
        case let .questionNotFound(id): "Question \(id) could not be found."
        case let .objectiveNotFound(id): "Learning objective \(id) could not be found."
        case let .persistence(message): "Progress could not be saved: \(message)"
        }
    }
}
