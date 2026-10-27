import Foundation
import Testing
@testable import FirstStateCore

@Suite("Account-scoped study records")
struct AccountProgressTests {
    @Test func twoAccountsKeepAllWorkspaceFieldsSeparate() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = AccountProgressFiles(legacy: FileProgressStore(fileURL: directory.appendingPathComponent("progress-v1.json")))
        let alice = UUID(), bob = UUID()
        var a = ProgressSnapshot(); a.hasCompletedOnboarding = true; a.profile.displayName = "Alice"
        a.workspace.lessonNotes = ["one": "Alice's notes"]
        a.workspace.counselorNotes = "Engineering"
        a.workspace.interests = ["physics"]
        a.workspace.sound = .brown
        a.workspace.avatarFilename = UUID().uuidString + ".jpg"
        a.workspace.awardedActivityIDs = Set(StudyCurriculum.units(for: "geometry").flatMap(\.activities).prefix(3).map(\.id))
        try files.store(for: alice).save(a)
        let newBob = try files.load(for: bob, inheritLegacy: false)
        #expect(newBob.workspace.lessonNotes.isEmpty)
        #expect(newBob.workspace.sound == .silence)
        #expect(newBob.workspace.avatarFilename == nil)
        #expect(StudyCurriculum.earnedXP(workspace: newBob.workspace) == 0)
        var b = newBob; b.profile.displayName = "Bob"; b.workspace.lessonNotes = ["one": "Bob's notes"]
        try files.store(for: bob).save(b)
        #expect(try files.load(for: alice, inheritLegacy: false) == a)
        #expect(try files.load(for: bob, inheritLegacy: false) == b)
        try files.store(for: bob).reset()
        #expect(try files.load(for: alice, inheritLegacy: false) == a)
    }
    @Test func legacyImportIsExplicitAndNeverOverwritesAnAccount() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let legacy = FileProgressStore(fileURL: directory.appendingPathComponent("progress-v1.json"))
        let files = AccountProgressFiles(legacy: legacy)
        var old = ProgressSnapshot(); old.profile.displayName = "Original learner"
        old.workspace.lessonNotes = ["legacy": "Keep this work"]
        try legacy.save(old)
        let first = UUID(), second = UUID()
        #expect(try files.load(for: first, inheritLegacy: true) == old)
        #expect(try files.load(for: second, inheritLegacy: false).workspace.lessonNotes.isEmpty)
        var migrated = old; migrated.profile.displayName = "First account"
        try files.store(for: first).save(migrated)
        #expect(try files.load(for: first, inheritLegacy: true) == migrated)
        #expect(try legacy.load() == old)
        #expect(files.store(for: first).fileURL != files.store(for: second).fileURL)
    }
}
