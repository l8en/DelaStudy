import Foundation

public protocol ProgressStore: Sendable {
    func load() throws -> ProgressSnapshot
    func save(_ snapshot: ProgressSnapshot) throws
    func reset() throws
}

public struct FileProgressStore: ProgressStore, Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public static func appStore(fileManager: FileManager = .default) throws -> FileProgressStore {
        let support = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = support.appendingPathComponent("FirstStateLens", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return FileProgressStore(fileURL: directory.appendingPathComponent("progress-v1.json"))
    }

    public func load() throws -> ProgressSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return ProgressSnapshot() }
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try Self.decoder.decode(ProgressSnapshot.self, from: data)
            guard snapshot.schemaVersion == ProgressSnapshot.currentSchemaVersion else {
                throw LearningError.persistence("Unsupported progress version \(snapshot.schemaVersion).")
            }
            guard Set(snapshot.attempts.map(\.id)).count == snapshot.attempts.count else {
                throw LearningError.persistence("Duplicate attempt identifiers were found.")
            }
            return snapshot
        } catch let error as LearningError { throw error }
        catch { throw LearningError.persistence("The saved progress file is unreadable. \(error.localizedDescription)") }
    }

    public func save(_ snapshot: ProgressSnapshot) throws {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try Self.encoder.encode(snapshot)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch { throw LearningError.persistence(error.localizedDescription) }
    }

    public func reset() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do { try FileManager.default.removeItem(at: fileURL) }
        catch { throw LearningError.persistence(error.localizedDescription) }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; encoder.dateEncodingStrategy = .iso8601; return encoder
    }
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601; return decoder
    }
}

/// UUID paths keep account identity independent of display names and login handles.
public struct AccountProgressFiles: Sendable {
    public let legacy: FileProgressStore
    public let directory: URL
    public init(legacy: FileProgressStore) {
        self.legacy = legacy
        directory = legacy.fileURL.deletingLastPathComponent().appendingPathComponent("Accounts", isDirectory: true)
    }
    public func store(for id: UUID) -> FileProgressStore {
        FileProgressStore(fileURL: directory.appendingPathComponent(id.uuidString, isDirectory: true).appendingPathComponent("progress-v1.json"))
    }
    public func load(for id: UUID, inheritLegacy: Bool) throws -> ProgressSnapshot {
        let target = store(for: id)
        if FileManager.default.fileExists(atPath: target.fileURL.path) { return try target.load() }
        return inheritLegacy ? try legacy.load() : ProgressSnapshot()
    }
}
