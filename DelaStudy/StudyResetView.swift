import SwiftUI

/// An optional gentle pacer, not a medical treatment or a claim of better grades.
struct StudyResetView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var started: Date?
    @State private var finished = false
    var body: some View {
        BearingPage(title: "One-minute reset", eyebrow: "Between study intervals") {
            Text("Take a quieter minute.").font(LensFont.title2.weight(.medium))
            Text("Breathe comfortably. Follow the guide only if it feels natural; there are no breath holds.").font(LensFont.body)
            TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 0.1, paused: started == nil)) { timeline in
                let elapsed = started.map { max(0, timeline.date.timeIntervalSince($0)) } ?? 0
                let phase = elapsed.truncatingRemainder(dividingBy: 10)
                let inhale = phase < 4
                let progress = inhale ? phase / 4 : 1 - (phase - 4) / 6
                VStack(spacing: 24) {
                    ZStack {
                        Circle().stroke(LensTheme.border, lineWidth: 1)
                        Circle().fill(LensTheme.accentWash).scaleEffect(reduceMotion || started == nil ? 0.8 : 0.56 + progress * 0.34)
                        VStack(spacing: 8) {
                            Text(started == nil ? (finished ? "Reset complete" : "Ready") : inhale ? "Breathe in" : "Breathe out").font(LensFont.title3.weight(.medium))
                            if started != nil { Text("\(max(0, 60-Int(elapsed)))s").font(LensFont.caption.monospacedDigit()) }
                        }
                    }.frame(height: 250).accessibilityElement(children: .combine)
                    if started != nil {
                        Button("Stop reset") { started = nil; finished = false }.frame(minHeight: 44)
                    } else {
                        Button(finished ? "Start another minute" : "Start reset") { finished = false; started = .now }.buttonStyle(LensPrimaryButtonStyle())
                    }
                }.onChange(of: elapsed >= 60) { _, complete in if complete { started = nil; finished = true } }
            }
            Text("Stop if you feel light-headed or uncomfortable. You can simply rest and breathe normally instead.").font(LensFont.subheadline)
            NavigationLink("Research & limitations") { SoundResearchView() }.frame(minHeight: 44)
        }.onChange(of: scenePhase) { _, phase in if phase != .active { started = nil } }
    }
}
