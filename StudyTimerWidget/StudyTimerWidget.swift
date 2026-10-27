import SwiftUI
import WidgetKit
import ActivityKit

@main
struct StudyTimerBundle: WidgetBundle {
    var body: some Widget { StudyTimerWidget() }
}
struct StudyTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyActivityAttributes.self) { context in
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FIRST STATE LENS").font(.caption2.monospaced().weight(.semibold)).foregroundStyle(Color(red: 0.78, green: 0.84, blue: 1))
                    Text(context.state.task).font(.headline).lineLimit(2)
                    Text("\(context.state.phase) · Interval \(context.state.interval)").font(.caption).foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Countdown(state: context.state).font(.system(size: 32, weight: .medium, design: .monospaced)).frame(maxWidth: 135)
            }.padding(18).foregroundStyle(.white)
                .activityBackgroundTint(Color(red: 0.07, green: 0.10, blue: 0.17))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "firststatelens://focus"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Label(context.state.phase, systemImage: "timer").font(.subheadline) }
                DynamicIslandExpandedRegion(.trailing) { Countdown(state: context.state).font(.title2.monospacedDigit()) }
                DynamicIslandExpandedRegion(.bottom) { Text(context.state.task).font(.subheadline).lineLimit(2) }
            } compactLeading: { Image(systemName: "timer") }
            compactTrailing: { Countdown(state: context.state).font(.caption.monospacedDigit()).frame(width: 48) }
            minimal: { Image(systemName: "timer") }
            .widgetURL(URL(string: "firststatelens://focus"))
        }
    }
}
private struct Countdown: View {
    let state: StudyActivityAttributes.ContentState
    var body: some View {
        Group {
            if let end = state.deadline {
                Text(timerInterval: min(Date.now, end)...end, countsDown: true).monospacedDigit()
            } else if state.awaitingNext { Text("Done") }
            else { Text(String(format: "%02d:%02d", Int(state.remaining)/60, Int(state.remaining)%60)) }
        }.lineLimit(1).minimumScaleFactor(0.65)
    }
}
