import ActivityKit
import Foundation
import Observation

@MainActor @Observable
final class FocusLiveActivity {
    var status = ""
    private var generation = UUID()
    private var pending: Task<Void, Never>?
    func sync(session: FocusSession?, enabled: Bool) {
        let token = UUID(); generation = token
        let previous = pending
        pending = Task { [weak self] in
            await previous?.value
            guard let self, self.generation == token else { return }
            let activities = Activity<StudyActivityAttributes>.activities
            guard let session, enabled else {
                for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
                self.status = ""
                return
            }
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                self.status = "Live Activities are off in iOS Settings. The in-app timer still works."
                return
            }
            let state = StudyActivityAttributes.ContentState(task: session.task,
                phase: session.phase == .work ? "Study" : "Break", deadline: session.deadline,
                remaining: session.remaining(at: .now), awaitingNext: session.awaitingNextPhase, interval: session.cycle)
            let content = ActivityContent(state: state, staleDate: session.deadline)
            if let existing = activities.first {
                await existing.update(content)
                for duplicate in activities.dropFirst() { await duplicate.end(nil, dismissalPolicy: .immediate) }
            } else {
                do {
                    _ = try Activity.request(attributes: StudyActivityAttributes(sessionID: session.id.uuidString), content: content, pushType: nil)
                    self.status = ""
                } catch { self.status = "Lock Screen timer unavailable. Open Focus to continue." }
            }
        }
    }
}
