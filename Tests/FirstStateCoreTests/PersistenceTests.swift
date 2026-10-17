import Foundation
import Testing
@testable import FirstStateCore

@Suite("Local progress persistence")
struct PersistenceTests {
    func temporaryStore() throws -> (FileProgressStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (FileProgressStore(fileURL: directory.appendingPathComponent("progress.json")), directory)
    }

    @Test func missingFileLoadsNewProgress() throws {
        let (store, directory) = try temporaryStore(); defer { try? FileManager.default.removeItem(at: directory) }
        #expect(try store.load() == ProgressSnapshot())
    }

    @Test func saveAndReloadPreservesAttemptAndSession() throws {
        let (store, directory) = try temporaryStore(); defer { try? FileManager.default.removeItem(at: directory) }
        let session = StudySession(objectiveID: "read-record", startedAt: Date(timeIntervalSince1970: 1))
        let attempt = Attempt(questionID: "record-date", objectiveID: "read-record", submittedChoiceID: "b", isCorrect: true, timestamp: Date(timeIntervalSince1970: 2), sessionID: session.id, contentVersion: 1)
        let expected = ProgressSnapshot(hasCompletedOnboarding: true, studyIntention: .understandDelaware, attempts: [attempt], sessions: [session])
        try store.save(expected)
        #expect(try store.load() == expected)
    }

    @Test func corruptDataFailsClearly() throws {
        let (store, directory) = try temporaryStore(); defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not-json".utf8).write(to: store.fileURL)
        #expect(throws: LearningError.self) { try store.load() }
    }

    @Test func duplicateAttemptIdentifiersAreRejected() throws {
        let (store, directory) = try temporaryStore(); defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID(); let session = UUID()
        let attempt = Attempt(id: id, questionID: "q", objectiveID: "o", submittedChoiceID: "a", isCorrect: true, timestamp: .now, sessionID: session, contentVersion: 1)
        try store.save(ProgressSnapshot(attempts: [attempt, attempt]))
        #expect(throws: LearningError.self) { try store.load() }
    }

    @Test func resetRemovesStoredProgress() throws {
        let (store, directory) = try temporaryStore(); defer { try? FileManager.default.removeItem(at: directory) }
        try store.save(ProgressSnapshot(hasCompletedOnboarding: true))
        try store.reset()
        #expect(try store.load() == ProgressSnapshot())
    }

    @Test func versionOneProgressMigratesWithDefaultProfile() throws {
        let (store, directory) = try temporaryStore(); defer { try? FileManager.default.removeItem(at: directory) }
        let json = #"{"schemaVersion":1,"hasCompletedOnboarding":true,"studyIntention":"understandDelaware","attempts":[],"sessions":[]}"#
        try Data(json.utf8).write(to: store.fileURL)
        let loaded = try store.load()
        #expect(loaded.schemaVersion == ProgressSnapshot.currentSchemaVersion)
        #expect(loaded.profile == LearnerProfile())
        #expect(loaded.hasCompletedOnboarding)
    }
}
