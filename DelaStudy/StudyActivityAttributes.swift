import ActivityKit
import Foundation

struct StudyActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let task: String
        let phase: String
        let deadline: Date?
        let remaining: Double
        let awaitingNext: Bool
        let interval: Int
    }
    let sessionID: String
}
