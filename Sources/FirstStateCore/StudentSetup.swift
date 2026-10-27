import Foundation

public enum StudyAim: String, Codable, CaseIterable, Sendable {
    case classwork, exams, college, curiosity
    public var title: String {
        switch self { case .classwork: "Keep up with class"; case .exams: "Prepare for a test"; case .college: "Get ready for college"; case .curiosity: "Explore a subject" }
    }
    public var symbol: String {
        switch self { case .classwork: "books.vertical"; case .exams: "checkmark.rectangle"; case .college: "building.columns"; case .curiosity: "sparkle.magnifyingglass" }
    }
}

public enum SetupStage: String, Codable, CaseIterable, Sendable {
    case year, aim, subjects, route, school, rhythm, ready
    public var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
    public var title: String {
        switch self { case .year: "Year"; case .aim: "Goal"; case .subjects: "Subjects"; case .route: "Route"; case .school: "School"; case .rhythm: "Rhythm"; case .ready: "Your lens" }
    }
}

/// A durable, account-scoped setup draft. Credentials never enter this record.
public struct StudentSetupDraft: Codable, Equatable, Sendable {
    public var stage: SetupStage = .year
    public var isInitialSetup = true
    public var year: String?
    public var aim: StudyAim?
    public var subjects: Set<String> = []
    public var route: AcademicRoute = .highSchool
    public var schoolID: String?
    public var dailyMinutes = 15
    public var workMinutes = 25
    public var breakMinutes = 5
    public var sound: StudySound = .silence
    public var courseID: String?
    public var addFirstTask = false
    public init() {}
    public init(snapshot: ProgressSnapshot, initial: Bool) {
        isInitialSetup = initial
        year = snapshot.workspace.academicYear; aim = snapshot.workspace.studyAim
        subjects = snapshot.workspace.interests
        route = snapshot.workspace.studyRoute ?? .highSchool; schoolID = snapshot.workspace.schoolID
        dailyMinutes = snapshot.profile.dailyGoalMinutes
        workMinutes = snapshot.workspace.focusPreferences.workMinutes; breakMinutes = snapshot.workspace.focusPreferences.breakMinutes
        sound = snapshot.workspace.sound; courseID = snapshot.profile.selectedCourseID
    }
    public static let years = ["9th grade", "10th grade", "11th grade", "12th grade", "College", "Independent study"]
    public var canContinue: Bool {
        switch stage {
        case .year: year != nil
        case .aim: aim != nil
        case .subjects: !subjects.isEmpty
        default: true
        }
    }
    public var completion: Double { Double(stage.index) / Double(SetupStage.allCases.count - 1) }
}

public enum StudentSetupEngine {
    public static func courses(for draft: StudentSetupDraft, content: LearningContent) -> [Course] {
        let pool = content.courses.filter { $0.level == draft.route.level }
        let selected = pool.filter { draft.subjects.contains($0.subject.rawValue) }
        return selected.isEmpty ? pool : selected
    }
    public static func finish(_ draft: StudentSetupDraft, snapshot: ProgressSnapshot, content: LearningContent) throws -> ProgressSnapshot {
        guard let year = draft.year, StudentSetupDraft.years.contains(year), draft.aim != nil,
              !draft.subjects.isEmpty, draft.subjects.isSubset(of: Set(CourseSubject.allCases.map(\.rawValue))) else {
            throw SetupError.incomplete
        }
        guard [5, 10, 15, 20, 30].contains(draft.dailyMinutes), (1...180).contains(draft.workMinutes), (1...30).contains(draft.breakMinutes) else { throw SetupError.invalidRhythm }
        if let school = draft.schoolID, school != "home", school != "outside", !SchoolDirectory.schools.contains(where: { $0.id == school }) { throw SetupError.invalidSchool }
        let suggestions = courses(for: draft, content: content)
        guard let course = suggestions.first(where: { $0.id == draft.courseID }) ?? suggestions.first else { throw SetupError.unavailableCourse }
        var updated = snapshot
        updated.profile.dailyGoalMinutes = draft.dailyMinutes; updated.profile.selectedCourseID = course.id
        updated.workspace.academicYear = year; updated.workspace.studyAim = draft.aim
        updated.workspace.interests = draft.subjects; updated.workspace.studyRoute = draft.route
        if draft.isInitialSetup || updated.workspace.schoolID != draft.schoolID { updated.workspace.includeSchoolInSummary = false }
        updated.workspace.schoolID = draft.schoolID
        updated.workspace.sound = draft.sound
        updated.workspace.focusPreferences.workMinutes = draft.workMinutes; updated.workspace.focusPreferences.breakMinutes = draft.breakMinutes
        updated.workspace.banner = course.subject.rawValue
        var saved = updated.workspace.savedCourseIDs ?? []; saved.insert(course.id); updated.workspace.savedCourseIDs = saved
        if draft.addFirstTask {
            let title = draft.aim == .exams ? "Practice \(course.title)" : "Study \(course.title)"
            if !updated.workspace.tasks.contains(where: { $0.title == title && !$0.isComplete }) {
                var task = PersonalTask(title: title); task.courseID = course.id; task.estimatedMinutes = draft.dailyMinutes
                updated.workspace.tasks.append(task)
            }
        }
        updated.workspace.academicSetupComplete = true; updated.workspace.studentSetup = nil
        return updated
    }
    public enum SetupError: LocalizedError {
        case incomplete, invalidRhythm, invalidSchool, unavailableCourse
        public var errorDescription: String? {
            switch self {
            case .incomplete: "Choose your year, a goal, and at least one subject."
            case .invalidRhythm: "Choose a daily goal and valid work/break durations."
            case .invalidSchool: "Choose a school from the directory, or keep your school private."
            case .unavailableCourse: "This route has no available courses. Choose another route."
            }
        }
    }
}
