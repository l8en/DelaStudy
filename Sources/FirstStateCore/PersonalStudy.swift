import Foundation

public enum AcademicRoute: String, Codable, CaseIterable, Sendable {
    case highSchool, honors, ap, college, sat, act
    public var title: String {
        switch self {
        case .highSchool: "High school"
        case .honors: "Honors support"
        case .ap: "AP preparation"
        case .college: "College foundations"
        case .sat: "SAT foundations"
        case .act: "ACT foundations"
        }
    }
    public var detail: String {
        switch self {
        case .highSchool: "Core subjects and your class materials"
        case .honors: "Foundation paths alongside your own classwork"
        case .ap: "Independent, selected-topic preparation"
        case .college: "Introductory college-level subjects"
        case .sat, .act: "Math and writing support, not a full test course"
        }
    }
    public var level: CourseLevel { self == .ap ? .apPreparation : self == .college ? .college : .highSchool }
}

public enum MaterialKind: String, Codable, CaseIterable, Sendable {
    case text, pdf, photo, youtube
    public var title: String {
        switch self { case .text: "Text"; case .pdf: "Document"; case .photo: "Photo text"; case .youtube: "YouTube" }
    }
    public var symbol: String {
        switch self { case .text: "text.alignleft"; case .pdf: "doc"; case .photo: "text.viewfinder"; case .youtube: "play.rectangle" }
    }
}

public struct RecallCard: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var question: String
    public var answer: String
    public var reviews = 0
    public var lastRecalled: Bool?
    public init(question: String, answer: String) { self.question = question; self.answer = answer }
}

public struct StudyMaterial: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var kind: MaterialKind
    public var text: String
    public var sourceName: String
    public var youtubeID: String?
    public var notes = ""
    public var cards: [RecallCard] = []
    public var createdAt = Date()
    public var updatedAt = Date()
    public init(title: String, kind: MaterialKind, text: String = "", sourceName: String = "", youtubeID: String? = nil) {
        self.title = title; self.kind = kind; self.text = text; self.sourceName = sourceName; self.youtubeID = youtubeID
    }
    public var validationError: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Give this material a title." }
        if title.count > 120 { return "Use a title of 120 characters or fewer." }
        if text.count > 60_000 || notes.count > 20_000 { return "Split this into smaller materials (60,000 source characters and 20,000 note characters maximum)." }
        if kind == .youtube {
            guard let youtubeID, Self.validVideoID(youtubeID) else { return "Use a valid YouTube video link." }
        } else if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Add some text before saving." }
        if cards.count > 100 { return "Keep each material to 100 cards or fewer." }
        if cards.contains(where: { $0.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.question.count > 2_000 || $0.answer.count > 4_000 }) {
            return "Each card needs a question and answer (2,000 and 4,000 characters maximum)."
        }
        return nil
    }
    public static func validVideoID(_ value: String) -> Bool {
        value.count == 11 && value.utf8.allSatisfy { (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 95 }
    }
    public static func videoID(from input: String) -> String? {
        guard let url = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https" || url.scheme?.lowercased() == "http", url.user == nil, url.password == nil,
              let host = url.host?.lowercased() else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        let candidate: String?
        if host == "youtu.be" { candidate = parts.first }
        else if ["youtube.com", "www.youtube.com", "m.youtube.com", "www.youtube-nocookie.com", "youtube-nocookie.com"].contains(host) {
            if parts.first == "watch" { candidate = url.queryItems?.first(where: { $0.name == "v" })?.value }
            else if ["embed", "shorts", "live"].contains(parts.first ?? ""), parts.count == 2 { candidate = parts[1] }
            else { candidate = nil }
        } else { candidate = nil }
        guard let candidate, validVideoID(candidate) else { return nil }
        return candidate
    }
}
