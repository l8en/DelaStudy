import SwiftUI
import UserNotifications

/// Retains a notification tap until the scene and its local account are ready.
@MainActor @Observable final class StudyNotificationRoute {
    static let shared = StudyNotificationRoute()
    var accountID: String?
    var sessionID: String?
    var requestID: UUID?
    func accept(accountID: String, sessionID: String) {
        self.accountID = accountID; self.sessionID = sessionID; requestID = UUID()
    }
    func clear() { accountID = nil; sessionID = nil; requestID = nil }
}

final class StudyAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           let account = info["accountID"] as? String, let session = info["sessionID"] as? String {
            Task { @MainActor in StudyNotificationRoute.shared.accept(accountID: account, sessionID: session) }
        }
        completionHandler()
    }
}

@main
struct FirstStateLensApp: App {
    @UIApplicationDelegateAdaptor(StudyAppDelegate.self) private var appDelegate
    @State private var model: AppModel

    init() {
        var store: FileProgressStore
        let storeError: String?
        do {
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("FirstStateLens-UI-tests.json")
                store = FileProgressStore(fileURL: url)
                if ProcessInfo.processInfo.arguments.contains("--reset-test-data") {
                    try store.reset()
                    let accounts = AccountProgressFiles(legacy: store).directory
                    if FileManager.default.fileExists(atPath: accounts.path) { try FileManager.default.removeItem(at: accounts) }
                }
            } else { store = try .appStore() }
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--reset-local-account") {
                let testing = ProcessInfo.processInfo.arguments.contains("--ui-testing")
                try LocalIdentity.resetSimulatorCredential(testing: testing)
                try store.reset()
                let accounts = AccountProgressFiles(legacy: store).directory
                if FileManager.default.fileExists(atPath: accounts.path) { try FileManager.default.removeItem(at: accounts) }
                let avatars = AvatarFiles.directory
                if FileManager.default.fileExists(atPath: avatars.path) { try FileManager.default.removeItem(at: avatars) }
            }
            #endif
            storeError = nil
        }
        catch {
            let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("FirstStateLens-unavailable.json")
            store = FileProgressStore(fileURL: fallback)
            storeError = error.localizedDescription
        }
        let loaded = AppModel(store: store, initialStoreError: storeError)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"), ProcessInfo.processInfo.arguments.contains("--seed-level") {
            loaded.updateWorkspace { $0.awardedActivityIDs = Set(StudyCurriculum.units(for: "algebra-i").flatMap(\.activities).prefix(9).map(\.id)) }
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"), ProcessInfo.processInfo.arguments.contains("--short-focus") {
            loaded.updateWorkspace { $0.focusPreferences.workMinutes = 1; $0.sound = .brown }
        }
        #endif
        _model = State(initialValue: loaded)
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .font(LensFont.body)
                .tint(LensTheme.teal)
                .preferredColorScheme(nil)
                .modifier(ReviewPresentation())
        }
    }
}

private struct ReviewPresentation: ViewModifier {
    func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--review-large"), ProcessInfo.processInfo.arguments.contains("--review-dark") {
            content.dynamicTypeSize(.accessibility2).preferredColorScheme(.dark)
        } else if ProcessInfo.processInfo.arguments.contains("--review-large") {
            content.dynamicTypeSize(.accessibility2)
        } else if ProcessInfo.processInfo.arguments.contains("--review-dark") {
            content.preferredColorScheme(.dark)
        } else { content }
        #else
        content
        #endif
    }
}
