import Foundation

/// Provenance accompanies every bundled cover; no network request is needed to browse.
public struct CourseImageRecord: Codable, Identifiable, Sendable {
    public let id: String
    public let courseIDs: [String]
    public let filename: String
    public let title: String
    public let creator: String
    public let institution: String
    public let sourceURL: URL
    public let originalURL: URL
    public let downloadURL: URL
    public let license: String
    public let licenseURL: URL
    public let credit: String
    public let accessedOn: String
    public let sourceDate: String
    public let modifications: String
    public let alt: String
    public let focalX: Double
    public let focalY: Double
    public let fit: String
    public let reason: String
    public let medium: String
    public let provenance: String
    public let sourceDescription: String
    public let filePageTitle: String
    public let sourceUploadDate: String
}

public enum CourseMedia {
    public static var directory: URL? {
        #if SWIFT_PACKAGE
        Bundle.module.url(forResource: "CourseMedia", withExtension: nil)
        #else
        Bundle.main.url(forResource: "CourseMedia", withExtension: nil)
        #endif
    }

    public static let all: [CourseImageRecord] = {
        guard let url = directory?.appendingPathComponent("catalog.json"),
              let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([CourseImageRecord].self, from: data) else { return [] }
        return records
    }()

    public static func image(for courseID: String) -> CourseImageRecord? {
        all.first { $0.courseIDs.contains(courseID) }
    }

    public static func url(for record: CourseImageRecord) -> URL? {
        directory?.appendingPathComponent(record.filename)
    }
}
