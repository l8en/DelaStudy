import SwiftUI

struct MasteryMapView: View {
    @Bindable var model: AppModel
    @State private var showList = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EditorialTitle(eyebrow: "Course map", title: "Your path")

                Picker("Trail presentation", selection: $showList) {
                    Text("Map").tag(false)
                    Text("Accessible list").tag(true)
                }
                .pickerStyle(.segmented)

                if showList {
                    VStack(spacing: 12) {
                        ForEach(model.progress, id: \.objective.id) { item in objectiveRow(item) }
                    }
                } else {
                    TrailCanvas(progress: model.progress)
                        .frame(height: 430)
                        .accessibilityHidden(true)
                }

                DisclosureGroup("How scores work") {
                    Text("Complete two correct answers and reach 70% to finish a lesson.")
                        .font(LensFont.footnote).foregroundStyle(LensTheme.navy).padding(.top, 8)
                }.font(LensFont.headline).foregroundStyle(LensTheme.navy)
            }
            .padding(24)
        }
        .background(LensTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.progress)
    }

    private func objectiveRow(_ item: ObjectiveProgress) -> some View {
        Button {
            if item.status != .locked { model.startSession(objectiveID: item.objective.id) }
        } label: {
            HStack(spacing: 14) {
                StatusMark(status: item.status)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.objective.title).font(LensFont.headline).foregroundStyle(LensTheme.navy)
                    Text(statusText(item)).font(LensFont.caption.weight(.semibold)).foregroundStyle(color(for: item.status))
                }
                Spacer()
                if item.status != .locked { Image(systemName: "chevron.right").foregroundStyle(LensTheme.slate) }
            }
            .padding(16).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(LensTheme.border))
        }
        .buttonStyle(.plain).disabled(item.status == .locked)
        .accessibilityLabel("\(item.objective.title), \(statusText(item)). \(item.objective.summary)")
        .accessibilityHint(item.status == .locked ? "Complete its prerequisite first" : "Starts practice for this lens")
    }

    private func statusText(_ item: ObjectiveProgress) -> String {
        switch item.status {
        case .locked: "Locked · prerequisite needed"
        case .ready: "Ready · not yet practiced"
        case .learning: "Learning · \(Int(item.mastery * 100))% estimate"
        case .review: "Review · \(Int(item.mastery * 100))% estimate"
        case .demonstrated: "Demonstrated · \(Int(item.mastery * 100))% estimate"
        }
    }

    private func color(for status: ObjectiveStatus) -> Color {
        switch status { case .demonstrated: LensTheme.success; case .review: LensTheme.error; case .ready, .learning: LensTheme.teal; case .locked: LensTheme.slate }
    }
}

private struct TrailCanvas: View {
    let progress: [ObjectiveProgress]
    var body: some View {
        GeometryReader { proxy in
            let points = positions(in: proxy.size)
            Canvas { context, _ in
                for index in 0..<(points.count - 1) {
                    var path = Path(); path.move(to: points[index]); path.addLine(to: points[index + 1])
                    let completed = progress.indices.contains(index) && progress[index].status == .demonstrated
                    context.stroke(path, with: .color(completed ? LensTheme.teal : LensTheme.border), style: StrokeStyle(lineWidth: completed ? 5 : 3, lineCap: .round, dash: completed ? [] : [7, 8]))
                }
            }
            ForEach(Array(progress.enumerated()), id: \.element.objective.id) { index, item in
                VStack(spacing: 7) {
                    StatusMark(status: item.status).font(LensFont.title)
                    Text(item.objective.title).font(LensFont.caption.weight(.semibold)).foregroundStyle(LensTheme.navy).multilineTextAlignment(.center).frame(width: 112)
                    if item.attemptCount > 0 { Text("\(Int(item.mastery * 100))%").font(LensFont.caption2.monospacedDigit()).foregroundStyle(LensTheme.slate) }
                }
                .position(points[index])
            }
        }
        .padding(.horizontal, 8)
    }

    private func positions(in size: CGSize) -> [CGPoint] {
        [CGPoint(x: size.width * 0.25, y: 60), CGPoint(x: size.width * 0.72, y: 160), CGPoint(x: size.width * 0.28, y: 270), CGPoint(x: size.width * 0.70, y: 380)]
    }
}

private struct StatusMark: View {
    let status: ObjectiveStatus
    var body: some View {
        Image(systemName: symbol).foregroundStyle(color).frame(width: 34, height: 34)
    }
    private var symbol: String {
        switch status { case .locked: "lock.circle"; case .ready: "circle.dotted"; case .learning: "circle.lefthalf.filled"; case .review: "arrow.counterclockwise.circle.fill"; case .demonstrated: "checkmark.circle.fill" }
    }
    private var color: Color {
        switch status { case .locked: LensTheme.slate; case .review: LensTheme.error; case .demonstrated: LensTheme.success; default: LensTheme.teal }
    }
}
