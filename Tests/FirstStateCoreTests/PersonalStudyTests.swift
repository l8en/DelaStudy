import Foundation
import Testing
@testable import FirstStateCore

@Suite("Personal study desk")
struct PersonalStudyTests {
    @Test func videoLinksAreStrictlyValidated() {
        for link in ["https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=12", "https://youtu.be/dQw4w9WgXcQ", "https://m.youtube.com/shorts/dQw4w9WgXcQ", "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"] {
            #expect(StudyMaterial.videoID(from: link) == "dQw4w9WgXcQ")
        }
        for link in ["javascript:alert(1)", "https://youtube.com.evil.test/watch?v=dQw4w9WgXcQ", "https://youtube.com@evil.test/watch?v=dQw4w9WgXcQ", "https://evil.test/dQw4w9WgXcQ", "https://youtube.com/watch?v=not-an-id", "https://youtube.com/embed/<script>", "dQw4w9WgXcQ"] {
            #expect(StudyMaterial.videoID(from: link) == nil)
        }
    }
    @Test func materialValidationAndRecallNeverManufactureMastery() {
        var material = StudyMaterial(title: "Cell notes", kind: .text, text: "Membranes regulate transport.")
        #expect(material.validationError == nil)
        material.cards = [RecallCard(question: "What regulates transport?", answer: "The cell membrane.")]
        material.cards[0].reviews = 1; material.cards[0].lastRecalled = true
        var snapshot = ProgressSnapshot(); snapshot.workspace.materials = [material]
        #expect(snapshot.attempts.isEmpty)
        #expect(StudyCurriculum.earnedXP(workspace: snapshot.workspace) == 0)
        material.cards[0].answer = "   "
        #expect(material.validationError != nil)
        material.cards = []; material.text = String(repeating: "x", count: 60_001)
        #expect(material.validationError != nil)
        #expect(StudyMaterial(title: "Video", kind: .youtube, youtubeID: "bad").validationError != nil)
    }
    @Test func oldWorkspaceDefaultsAndNewFieldsRoundTrip() throws {
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        let baseline = try encoder.encode(LearnerWorkspace())
        var old = try #require(JSONSerialization.jsonObject(with: baseline) as? [String: Any])
        for field in ["materials", "academicYear", "studyRoute", "academicSetupComplete"] { old.removeValue(forKey: field) }
        let decoded = try decoder.decode(LearnerWorkspace.self, from: JSONSerialization.data(withJSONObject: old))
        #expect(decoded.materials == nil && decoded.academicYear == nil && decoded.studyRoute == nil)
        var workspace = decoded
        workspace.academicYear = "12th grade"; workspace.studyRoute = .ap; workspace.academicSetupComplete = true
        workspace.materials = [StudyMaterial(title: "Independent notes", kind: .text, text: "Original class material")]
        #expect(try decoder.decode(LearnerWorkspace.self, from: encoder.encode(workspace)) == workspace)
    }
    @Test func materialsAndAcademicContextStayAccountScoped() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = AccountProgressFiles(legacy: FileProgressStore(fileURL: directory.appendingPathComponent("progress.json")))
        let first = UUID(), second = UUID()
        var a = ProgressSnapshot(); a.workspace.academicYear = "11th grade"; a.workspace.studyRoute = .honors
        a.workspace.materials = [StudyMaterial(title: "Private coursework", kind: .photo, text: "Recognized text")]
        a.workspace.materials?[0].createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        a.workspace.materials?[0].updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        try files.store(for: first).save(a)
        #expect(try files.load(for: second, inheritLegacy: false).workspace.materials == nil)
        #expect(try files.load(for: second, inheritLegacy: false).workspace.studyRoute == nil)
        #expect(try files.load(for: first, inheritLegacy: false) == a)
    }
}
