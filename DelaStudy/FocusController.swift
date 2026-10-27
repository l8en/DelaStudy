import SwiftUI
import UserNotifications
import AudioToolbox
import Observation

@MainActor @Observable
final class FocusController {
    unowned let model: AppModel
    let audio = StudyAudio()
    var liveActivity: FocusLiveActivity { model.focusLiveActivity }
    var alertStatus = "Alerts are optional"
    private var monotonicAnchor: (date: Date, uptime: TimeInterval)?
    private var observedID: UUID?
    private let notificationID = "first-bearing-focus-deadline"
    private let accountID: UUID?
    private var isCurrentAccount: Bool { model.identity.unlocked && model.identity.accountID == accountID }
    init(model: AppModel) { self.model = model; accountID = model.identity.accountID }

    /// Monotonic time while this process is alive; a persisted wall deadline across relaunch.
    var now: Date {
        if let anchor = monotonicAnchor { return anchor.date.addingTimeInterval(ProcessInfo.processInfo.systemUptime - anchor.uptime) }
        return .now
    }
    func start(task: String, objectiveID: String? = nil, playSound: Bool = true) {
        guard isCurrentAccount else { return }
        guard model.snapshot.workspace.focus == nil else { return }
        let title = task.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = FocusSession(task: title.isEmpty ? "Independent study" : String(title.prefix(120)), objectiveID: objectiveID, preferences: model.snapshot.workspace.focusPreferences, now: .now)
        guard model.updateWorkspace({ $0.focus = session }) else { return }
        anchor(); schedule()
        let w = model.snapshot.workspace
        if playSound && w.sound != .silence { audio.play(w.sound, level: w.soundLevel) }
        syncAudioDeadline()
    }
    func anchor() { monotonicAnchor = (.now, ProcessInfo.processInfo.systemUptime) }
    func tick(allowFeedback: Bool = true) {
        guard isCurrentAccount else { return }
        guard var session = model.snapshot.workspace.focus else { return }
        if observedID != session.id { observedID = session.id; if monotonicAnchor == nil { anchor() } }
        let before = session
        let record = session.settle(at: now)
        guard before != session else { return }
        let config = session.configuration
        let wasWork = session.phase == .work
        let absent = session.recoveryMessage != nil
        if config.automaticBreak && wasWork && !absent { session.nextPhase(at: now) }
        guard model.updateWorkspace({ workspace in
            workspace.focus = session
            if let record, !workspace.focusHistory.contains(where: { $0.id == record.id }) { workspace.focusHistory.append(record) }
        }) else { return }
        cancelAlert()
        if model.snapshot.workspace.stopSoundAtEnd { audio.stop() }
        if !absent && allowFeedback {
            if config.completionSound { AudioServicesPlaySystemSound(1007) }
            if config.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
        schedule()
    }
    func togglePause() {
        guard isCurrentAccount else { return }
        tick()
        guard var session = model.snapshot.workspace.focus, !session.awaitingNextPhase else { return }
        if session.isRunning { session.pause(at: now) } else { session.resume(at: now) }
        if model.updateWorkspace({ $0.focus = session }) { cancelAlert(); schedule(); syncAudioDeadline() }
    }
    func next(skipBreak: Bool = false) {
        guard isCurrentAccount else { return }
        guard var s = model.snapshot.workspace.focus else { return }
        s.nextPhase(at: now, skipBreak: skipBreak)
        if model.updateWorkspace({ $0.focus = s }) { cancelAlert(); schedule(); syncAudioDeadline() }
    }
    func finishEarly() {
        guard isCurrentAccount else { return }
        tick()
        guard let session = model.snapshot.workspace.focus else { return }
        let record = session.awaitingNextPhase ? nil : session.record(at: now, completed: false)
        guard model.updateWorkspace({ w in
            if let record, !w.focusHistory.contains(where: { $0.id == record.id }) { w.focusHistory.append(record) }
            w.focus = nil
        }) else { return }
        cancelAlert(); audio.stop(); monotonicAnchor = nil
        liveActivity.sync(session: nil, enabled: false)
    }
    func restore() {
        guard isCurrentAccount else { return }
        if var s = model.snapshot.workspace.focus, let deadline=s.deadline, deadline.timeIntervalSinceNow > s.duration+5 {
            s.deadline=nil; s.resumedAt=nil
            s.recoveryMessage="The device clock changed. The timer is paused; review it before resuming."
            model.updateWorkspace { $0.focus=s }
        }
        anchor(); tick(allowFeedback:false); schedule(); syncAudioDeadline()
    }
    func syncAudioDeadline() {
        audio.stop(at: model.snapshot.workspace.stopSoundAtEnd ? model.snapshot.workspace.focus?.deadline : nil)
    }
    func cancelAlert() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID]) }
    func requestAlerts() async {
        guard isCurrentAccount else { return }
        do {
            let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            alertStatus = allowed ? "Session alerts enabled" : "Alerts unavailable. The timer still works."
            schedule()
        } catch { alertStatus = "Alerts unavailable. The timer still works." }
    }
    func schedule() {
        guard isCurrentAccount else { return }
        cancelAlert()
        syncAudioDeadline()
        liveActivity.sync(session: model.snapshot.workspace.focus, enabled: model.snapshot.workspace.showLiveActivity ?? true)
        let alerts = model.snapshot.workspace.focusPreferences
        guard let s = model.snapshot.workspace.focus, s.isRunning,
              s.phase == .work ? alerts.alerts : alerts.breakAlerts else { return }
        let content = UNMutableNotificationContent()
        content.title = s.phase == .work ? "Study interval complete" : "Break complete"
        content.body = s.phase == .work ? "Your focus interval is finished. Tap to review your session and start a break." : "Your break is finished. Tap to return to your study session."
        content.threadIdentifier = "delastudy-focus"
        content.userInfo = ["accountID": accountID?.uuidString ?? "", "sessionID": s.id.uuidString]
        if s.configuration.completionSound { content.sound = .default }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, s.remaining(at: now)), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)) { [weak self] error in
            if error != nil { Task { @MainActor in self?.alertStatus="Alerts unavailable. The timer still works." } }
        }
    }
}

extension AppModel {
    var focus: FocusController {
        if let focusController { return focusController }
        let controller = FocusController(model: self); focusController = controller; return controller
    }
}
