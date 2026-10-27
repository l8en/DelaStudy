import Foundation

/// Edited explanations, not mechanically shortened textbook paragraphs. The source
/// chapter remains available separately; these cover three selected ideas only.
public enum BiteLessons {
    public static let version = "bite-v1"
    private static let catalog: [String: [ReadingFact]] = {
        guard let url = StudyCurriculum.directory?.appendingPathComponent("bite-lessons.json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: [ReadingFact]].self, from: data)) ?? [:]
    }()
    public static func facts(for reading: StudyReading) -> [ReadingFact] { catalog[reading.id] ?? [] }
    public static func step(for reading: StudyReading, workspace: LearnerWorkspace) -> Int {
        min(max(0, workspace.biteStepPositions?[reading.id] ?? 0), max(0, facts(for: reading).count - 1))
    }
    public static func moving(to step: Int, reading: StudyReading, workspace: LearnerWorkspace) -> LearnerWorkspace {
        var updated = workspace
        let index = min(max(0, step), max(0, facts(for: reading).count - 1))
        updated.biteStepPositions = (updated.biteStepPositions ?? [:]).merging([reading.id: index]) { _, new in new }
        return updated
    }
}

public enum CourseResourceKind: String, CaseIterable, Identifiable, Sendable {
    case videos, textbooks, readings, frameworks
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .videos: "Videos"
        case .textbooks: "Textbooks"
        case .readings: "Full readings"
        case .frameworks: "Curriculum & standards"
        }
    }
    public var symbol: String {
        switch self {
        case .videos: "play.rectangle"
        case .textbooks: "books.vertical"
        case .readings: "text.book.closed"
        case .frameworks: "checklist"
        }
    }
}

public struct CourseResource: Identifiable, Sendable {
    public let kind: CourseResourceKind
    public let title: String
    public let publisher: String
    public let url: URL
    public let readingID: String?
    public let video: LessonVideo?
    public var id: String { "\(kind.rawValue):\(url.absoluteString)" }
}

/// Derived only from the course's real linked sources. No invented videos, books,
/// endorsements, or network requirement for studying the short lessons.
public enum CourseResources {
    public static func items(for course: Course, content: LearningContent) -> [CourseResource] {
        var items: [CourseResource] = []
        let materials = course.objectiveIDs.compactMap { content.lesson(for: $0) }
        for video in materials.compactMap(\.video) {
            items.append(CourseResource(kind: .videos, title: video.title, publisher: video.channel, url: video.watchURL, readingID: nil, video: video))
        }
        let readings = StudyCurriculum.units(for: course.id).flatMap(\.readingURLs).compactMap { StudyCurriculum.readings[$0.absoluteString] }
        for reading in readings {
            items.append(CourseResource(kind: .readings, title: StudyTitle.display(reading.title), publisher: reading.book, url: reading.sourceURL, readingID: reading.id, video: nil))
            if reading.sourceURL.host == "openstax.org", let range = reading.sourceURL.path.range(of: "/pages/") {
                let book = String(reading.sourceURL.path[..<range.lowerBound]).replacingOccurrences(of: "/books/", with: "")
                if let url = URL(string: "https://openstax.org/details/books/\(book)") {
                    items.append(CourseResource(kind: .textbooks, title: reading.book, publisher: "OpenStax · Rice University", url: url, readingID: nil, video: nil))
                }
            } else if reading.sourceURL.host?.hasSuffix("gutenberg.org") == true {
                var bookURL = URLComponents(url: reading.sourceURL, resolvingAgainstBaseURL: false)
                bookURL?.fragment = nil
                items.append(CourseResource(kind: .textbooks, title: reading.book, publisher: "Project Gutenberg", url: bookURL?.url ?? reading.sourceURL, readingID: nil, video: nil))
            }
        }
        for material in materials {
            items.append(CourseResource(kind: .readings, title: content.objective(id: material.objectiveID)?.title ?? "Foundation reading", publisher: course.curriculum.provider, url: material.readingURL, readingID: nil, video: nil))
        }
        items.append(CourseResource(kind: .frameworks, title: course.curriculum.title, publisher: course.curriculum.provider, url: course.curriculum.url, readingID: nil, video: nil))
        if let ap = APPreparation.module(for: course.id) {
            items.append(CourseResource(kind: .frameworks, title: "AP course framework", publisher: "College Board", url: ap.frameworkURL, readingID: nil, video: nil))
        }
        var seen: Set<String> = []
        return items.filter { seen.insert($0.id).inserted }
    }
}
