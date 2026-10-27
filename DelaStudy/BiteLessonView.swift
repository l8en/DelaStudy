import SwiftUI

/// A short explanation occupies the reading surface; the action stays reachable
/// while large text can scroll. Advancing saves before moving the visible step.
struct BiteLessonView: View {
    @Bindable var model: AppModel
    let reading: StudyReading
    let activityID: String
    let onPractice: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var backwards = false
    @State private var credits = false
    @AccessibilityFocusState private var stepFocused: Bool
    private var facts: [ReadingFact] { BiteLessons.facts(for: reading) }
    private var earned: Bool { model.snapshot.workspace.awardedActivityIDs?.contains(activityID) == true }
    private var quiet: Bool { reduceMotion || model.quietFocus }
    private var sourceTitle: String { reading.book.replacingOccurrences(of: "First State Lens", with: "DelaStudy") }
    var body: some View {
        Group {
            if facts.isEmpty {
                ContentUnavailableView("Lesson couldn't load", systemImage: "book.closed", description: Text("Return to the course and try again. Your progress is unchanged."))
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        ForEach(facts.indices, id: \.self) { step in
                            Capsule().fill(step <= index ? LensTheme.teal : LensTheme.border).frame(height: 5)
                        }
                    }.padding(.horizontal, 22).padding(.top, 12).accessibilityHidden(true)
                    ScrollViewReader { scroll in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                HStack {
                                    Text("\(index + 1) of \(facts.count)").font(LensFont.subheadline.monospacedDigit()).foregroundStyle(LensTheme.teal)
                                        .accessibilityIdentifier("lesson-step-position")
                                    Spacer()
                                }
                                Text(StudyTitle.display(reading.title)).font(LensFont.title2.weight(.bold)).tracking(-0.5)
                                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                                    .id("step-top")
                                Text(highlighted(facts[index])).font(LensFont.title3).lineSpacing(7)
                                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                                    .accessibilityFocused($stepFocused).accessibilityIdentifier("lesson-step-body")
                                if reading.title == "Angle relationships" {
                                    AngleLessonSketch(step: index).frame(height: 170).padding(.top, 8)
                                }
                            }.padding(22).frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
                                .id(index)
                                .transition(quiet ? .opacity : .asymmetric(insertion: .offset(x: backwards ? -16 : 16).combined(with: .opacity), removal: .opacity))
                        }.onChange(of: index) { _, _ in
                            scroll.scrollTo("step-top", anchor: .top)
                            stepFocused = true
                        }
                    }
                    Button { credits = true } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "info.circle")
                            Text(sourceTitle).lineLimit(2)
                            Spacer(minLength: 0)
                        }.font(LensFont.caption).foregroundStyle(LensTheme.slate).padding(.horizontal, 22).frame(minHeight: 44)
                    }.buttonStyle(.plain).accessibilityLabel("Lesson credits and source: \(sourceTitle)")
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { previous; next }
                        VStack(spacing: 8) { next; previous }
                    }.padding(.horizontal, 20).padding(.vertical, 12).background(LensTheme.paper)
                }
            }
        }.onAppear { index = BiteLessons.step(for: reading, workspace: model.snapshot.workspace) }
            .animation(quiet ? nil : .easeInOut(duration: 0.2), value: index)
            .sheet(isPresented: $credits) {
                NavigationStack {
                    BearingPage(title: "Lesson credits", eyebrow: "Sources") {
                        Text("Three selected ideas adapted for short practice. The complete section is in this course's Resources tab.").font(LensFont.body)
                        Text(sourceTitle).font(LensFont.headline)
                        Text(reading.title).font(LensFont.subheadline)
                        Text(reading.license).font(LensFont.subheadline)
                        if let license = reading.licenseURL { Link("License terms", destination: license).frame(minHeight: 44) }
                        Link("Original source", destination: reading.sourceURL).frame(minHeight: 44)
                        if model.snapshot.workspace.completedActivityIDs?.contains(activityID) == true {
                            Button("Mark lesson as unfinished") {
                                if model.updateWorkspace({ $0.completedActivityIDs?.remove(activityID) }) { credits = false }
                            }.frame(minHeight: 44)
                        }
                    }.toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { credits = false } } }
                }
            }
    }
    private var previous: some View {
        Button { move(to: index - 1) } label: {
            Label("Back", systemImage: "arrow.left").font(LensFont.subheadline.weight(.semibold)).frame(minWidth: 76, minHeight: 48)
        }.buttonStyle(.plain).disabled(index == 0).foregroundStyle(index == 0 ? LensTheme.slate : LensTheme.teal)
            .accessibilityIdentifier("previous-lesson-step")
    }
    private var next: some View {
        Button {
            if index == facts.count - 1 { onPractice() }
            else { move(to: index + 1) }
        } label: {
            HStack(spacing: 10) {
                Text(index == facts.count - 1 ? (earned ? "Start practice" : "Start practice · +10 XP") : "Continue")
                Spacer(minLength: 6)
                Image(systemName: "arrow.right")
            }.padding(.horizontal, 16)
        }.buttonStyle(LensPrimaryButtonStyle())
            .accessibilityIdentifier(index == facts.count - 1 ? "complete-study-activity" : "next-lesson-step")
    }
    private func move(to newIndex: Int) {
        guard facts.indices.contains(newIndex) else { return }
        let updated = BiteLessons.moving(to: newIndex, reading: reading, workspace: model.snapshot.workspace)
        guard model.updateWorkspace({ $0.biteStepPositions = updated.biteStepPositions }) else { return }
        backwards = newIndex < index
        index = newIndex
    }
    private func highlighted(_ fact: ReadingFact) -> AttributedString {
        var text = AttributedString(fact.evidence)
        if let range = text.range(of: fact.answer, options: .caseInsensitive) {
            text[range].font = LensFont.title3.weight(.bold)
            text[range].foregroundColor = LensTheme.teal
        }
        return text
    }
}

/// Instructional geometry, not decorative artwork. Labels and sector sizes match
/// the example; VoiceOver receives the same relationship without reading paths.
private struct AngleLessonSketch: View {
    let step: Int
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.54)
            let radius = min(size.width * 0.43, size.height * 0.48)
            func point(_ degrees: Double, _ length: CGFloat) -> CGPoint {
                let radians = degrees * .pi / 180
                return CGPoint(x: center.x + cos(radians) * length, y: center.y + sin(radians) * length)
            }
            func sector(_ start: Double, _ end: Double, color: Color) {
                var path = Path(); path.move(to: center)
                for i in 0...32 { path.addLine(to: point(start + (end - start) * Double(i) / 32, radius * 0.63)) }
                path.closeSubpath(); context.fill(path, with: .color(color.opacity(0.15)))
            }
            let rays: [Double]
            let labels: [(String, Double)]
            if step == 0 {
                sector(-55, 0, color: LensTheme.teal); sector(125, 180, color: LensTheme.teal)
                rays = [0, 180, -55, 125]; labels = [("equal", -27.5), ("equal", 152.5)]
            } else if step == 1 {
                sector(-70, 0, color: LensTheme.teal); sector(-180, -70, color: LensTheme.gold)
                rays = [0, -70, -180]; labels = [("70°", -35), ("110°", -125)]
            } else {
                sector(-40, 0, color: LensTheme.teal); sector(-110, -40, color: LensTheme.gold)
                rays = [0, -40, -110]; labels = [("40°", -20), ("70°", -75)]
            }
            for angle in rays {
                var line = Path(); line.move(to: center); line.addLine(to: point(angle, radius))
                context.stroke(line, with: .color(LensTheme.navy), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(LensTheme.navy))
            for (label, angle) in labels {
                context.draw(Text(label).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy), at: point(angle, radius * 0.96))
            }
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel(step == 0 ? "Two intersecting lines. The opposite highlighted angles are equal." : step == 1 ? "A straight line split into adjacent angles of 70 and 110 degrees. Together they make 180 degrees." : "Adjacent angles of 40 and 70 degrees share a vertex and one side. They do not form a straight line.")
    }
}
