import Foundation
import Testing
import ImageIO
@testable import FirstStateCore

@Suite("Bundled course image collection")
struct CourseMediaTests {
    @Test func everyCourseHasOneTraceableImage() throws {
        let content = AppContent.content
        #expect(!CourseMedia.all.isEmpty)
        let mapped = CourseMedia.all.flatMap(\.courseIDs)
        #expect(Set(mapped) == Set(content.courses.map(\.id)))
        #expect(mapped.count == Set(mapped).count)
        #expect(Set(CourseMedia.all.map(\.id)).count == CourseMedia.all.count)
        for course in content.courses {
            #expect(CourseMedia.image(for: course.id) != nil)
        }
        #expect(CourseMedia.image(for: "unpublished-course") == nil)
        for record in CourseMedia.all {
            #expect(!record.title.isEmpty && !record.creator.isEmpty && !record.provenance.isEmpty)
            #expect(!record.alt.isEmpty && !record.reason.isEmpty && !record.modifications.isEmpty)
            #expect(!record.credit.isEmpty && !record.sourceDate.isEmpty && !record.medium.isEmpty)
            #expect(record.sourceURL.host == "commons.wikimedia.org")
            #expect(record.originalURL.host == "upload.wikimedia.org")
            #expect(record.sourceURL.scheme == "https" && record.licenseURL.scheme == "https")
            #expect(record.license.hasPrefix("CC BY") || record.license == "CC0" || record.license == "Public domain")
            #expect(record.focalX >= 0 && record.focalX <= 1 && record.focalY >= 0 && record.focalY <= 1)
            #expect(["fit", "fill"].contains(record.fit))
            #expect(!record.filename.contains("/") && record.filename.hasSuffix(".jpg"))
        }
    }

    @Test func everyShippingImageDecodesLocallyWithinBudget() throws {
        var total = 0
        for record in CourseMedia.all {
            let url = try #require(CourseMedia.url(for: record))
            let data = try Data(contentsOf: url)
            total += data.count
            #expect(data.starts(with: [0xFF, 0xD8]))
            let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
            let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, options))
            #expect(image.width > 0 && image.height > 0)
            #expect(max(image.width, image.height) <= 960)
        }
        #expect(total > 0 && total < 12 * 1024 * 1024)
    }

    @Test func reusedImagesStayWithinRelatedSubjects() throws {
        for record in CourseMedia.all where record.courseIDs.count > 1 {
            let subjects = Set(record.courseIDs.compactMap { AppContent.content.course(id: $0)?.subject })
            #expect(subjects.count == 1)
        }
        #expect(CourseMedia.image(for: "first-state-civics")?.medium == "Archival document")
        #expect(CourseMedia.image(for: "environmental-science")?.medium == "Satellite image")
    }
}
