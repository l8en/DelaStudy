import Foundation
import Observation
import Security
import CommonCrypto
import LocalAuthentication

/// Multiple private accounts, not a hosted identity provider. No raw passwords on disk.
@MainActor @Observable final class LocalIdentity {
    var username: String?
    var accountID: UUID?
    var hasAccounts = false
    var unlocked = false
    var error: String?
    var busy = false
    var recoveryUsername: String?
    private var failures = 0
    private var retryAt = Date.distantPast
    private let service: String
    private struct Credential: Codable, Sendable {
        let id: UUID
        let username: String
        let salt: Data
        let verifier: Data
        let inheritsLegacy: Bool
    }
    private struct LegacyCredential: Codable {
        let username: String
        let salt: Data
        let verifier: Data
    }
    init() {
        let testing = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        service = testing ? "com.firststatelens.test-profile" : "com.firststatelens.local-profile"
        do {
            if testing && ProcessInfo.processInfo.arguments.contains("--reset-test-data") { try Self.clear(service: service) }
            #if DEBUG
            if testing && ProcessInfo.processInfo.arguments.contains("--seed-legacy-account") {
                let salt = Data(repeating: 7, count: 32)
                let old = LegacyCredential(username: "Avery", salt: salt, verifier: try Self.derive("StudyTestOnly42", salt: salt))
                var request = query(key: "device-profile")
                request[kSecValueData as String] = try JSONEncoder().encode(old)
                request[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                guard SecItemAdd(request as CFDictionary, nil) == errSecSuccess else { throw IdentityError.storage }
            }
            #endif
            // Publish the new vault before retiring the old record. A failed migration leaves it intact.
            if try data(key: "accounts-v2") == nil, let data = try data(key: "device-profile") {
                let old = try JSONDecoder().decode(LegacyCredential.self, from: data)
                try save([Credential(id: UUID(), username: old.username, salt: old.salt, verifier: old.verifier, inheritsLegacy: true)])
            }
            let accounts = try read()
            hasAccounts = !accounts.isEmpty
            username = accounts.count == 1 ? accounts.first?.username : nil
            if hasAccounts { SecItemDelete(query(key: "device-profile") as CFDictionary) }
        } catch { self.error = error.localizedDescription }
    }
    private func query(key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: key]
    }
    private func data(key: String) throws -> Data? {
        var request = query(key: key); request[kSecReturnData as String] = true; request[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw IdentityError.storage }
        return data
    }
    private func read() throws -> [Credential] {
        guard let data = try data(key: "accounts-v2") else { return [] }
        let accounts = try JSONDecoder().decode([Credential].self, from: data)
        guard Set(accounts.map { Self.canonical($0.username) }).count == accounts.count,
              Set(accounts.map(\.id)).count == accounts.count else { throw IdentityError.storage }
        return accounts
    }
    private func save(_ accounts: [Credential]) throws {
        let data = try JSONEncoder().encode(accounts)
        let request = query(key: "accounts-v2")
        let status = SecItemUpdate(request as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var addition = request
            addition[kSecValueData as String] = data
            addition[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(addition as CFDictionary, nil) == errSecSuccess else { throw IdentityError.storage }
        } else if status != errSecSuccess { throw IdentityError.storage }
    }
    private static func canonical(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    static func validUsername(_ value: String) -> Bool { value.range(of: "^[A-Za-z0-9_]{3,24}$", options: .regularExpression) != nil }
    static func validPassword(_ value: String) -> Bool { value.count >= 10 && value.utf8.count <= 256 }

    /// The completion must successfully load/save the account's own progress before it is unlocked.
    func create(username raw: String, password: String, complete: @escaping (String, UUID, Bool) -> Bool) async {
        guard !busy else { return }
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.validUsername(name), Self.validPassword(password) else { error = "Use 3 to 24 letters, numbers or underscores, and a password of at least 10 characters."; return }
        busy = true; error = nil; defer { busy = false }
        do {
            var accounts = try read()
            let existing = accounts.firstIndex { Self.canonical($0.username) == Self.canonical(name) }
            let recovering = recoveryUsername.map { Self.canonical($0) == Self.canonical(name) } == true
            guard existing == nil || recovering else { throw IdentityError.usernameTaken }
            guard !recovering || existing != nil else { throw IdentityError.missing }
            let original = accounts
            let id = existing.map { accounts[$0].id } ?? UUID()
            let inherit = existing.map { accounts[$0].inheritsLegacy } ?? accounts.isEmpty
            var salt = Data(count: 32)
            let status = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
            guard status == errSecSuccess else { throw IdentityError.storage }
            let fixedSalt = salt
            let verifier = try await Task.detached(priority: .userInitiated) { try Self.derive(password, salt: fixedSalt) }.value
            let credential = Credential(id: id, username: name, salt: salt, verifier: verifier, inheritsLegacy: inherit)
            if let existing { accounts[existing] = credential } else { accounts.append(credential) }
            try save(accounts)
            guard complete(name, id, inherit) else { try save(original); return }
            self.username = name; accountID = id; hasAccounts = true; recoveryUsername = nil; unlocked = true
        } catch { self.error = error.localizedDescription }
    }
    func signIn(username: String, password: String, complete: @escaping (String, UUID, Bool) -> Bool) async {
        guard !busy else { return }
        guard Date.now >= retryAt else { error = "Wait a moment before trying again."; return }
        busy = true; error = nil; defer { busy = false }
        do {
            let accounts = try read()
            guard let credential = accounts.first(where: { Self.canonical($0.username) == Self.canonical(username) }) else {
                failures += 1; if failures >= 5 { retryAt = .now.addingTimeInterval(30) }
                throw accounts.isEmpty ? IdentityError.missing : IdentityError.invalid
            }
            let value = try await Task.detached(priority: .userInitiated) { try Self.derive(password, salt: credential.salt) }.value
            guard value.count == credential.verifier.count,
                  zip(value, credential.verifier).reduce(UInt8(0), { $0 | ($1.0 ^ $1.1) }) == 0 else {
                failures += 1; if failures >= 5 { retryAt = .now.addingTimeInterval(30) }; throw IdentityError.invalid
            }
            guard complete(credential.username, credential.id, credential.inheritsLegacy) else { return }
            failures = 0; self.username = credential.username; accountID = credential.id; recoveryUsername = nil; unlocked = true
        } catch { self.error = error.localizedDescription }
    }
    func recover(username: String) async {
        guard !busy else { return }
        busy = true; error = nil; defer { busy = false }
        do {
            guard let credential = try read().first(where: { Self.canonical($0.username) == Self.canonical(username) }) else { throw IdentityError.missing }
            let context = LAContext()
            guard try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Reset the password for \(credential.username) without changing their study progress.") else { return }
            recoveryUsername = credential.username
        } catch let failure as IdentityError { error = failure.localizedDescription }
        catch { self.error = "Couldn’t verify this device’s owner. Try again with device authentication available." }
    }
    func cancelRecovery() { recoveryUsername = nil; error = nil }
    func signOut() { unlocked = false; accountID = nil; recoveryUsername = nil; error = nil }
    private static func clear(service: String) throws {
        for key in ["device-profile", "accounts-v2"] {
            let request: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: key]
            let status = SecItemDelete(request as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw IdentityError.storage }
        }
    }
    #if DEBUG && targetEnvironment(simulator)
    static func resetSimulatorCredential(testing: Bool) throws {
        try clear(service: testing ? "com.firststatelens.test-profile" : "com.firststatelens.local-profile")
    }
    #endif
    nonisolated private static func derive(_ password: String, salt: Data) throws -> Data {
        var result = Data(count: 32)
        let bytes = Array(password.utf8)
        let status = result.withUnsafeMutableBytes { output in salt.withUnsafeBytes { saltBytes in bytes.withUnsafeBytes { input in
            CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), input.baseAddress, bytes.count, saltBytes.baseAddress, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 210_000, output.baseAddress, 32)
        } } }
        guard status == kCCSuccess else { throw IdentityError.storage }; return result
    }
    enum IdentityError: LocalizedError {
        case storage, invalid, missing, usernameTaken
        var errorDescription: String? { switch self {
        case .storage: "Your account couldn’t be saved or opened. Unlock your iPhone and try again."
        case .invalid: "The username or password doesn’t match. Try again."
        case .missing: "No account matches yet. Choose Create account to get started."
        case .usernameTaken: "That username is taken. Try another."
        } }
    }
}
