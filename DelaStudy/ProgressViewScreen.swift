import SwiftUI

struct ProgressViewScreen: View {
    @Bindable var model: AppModel
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                EditorialTitle(eyebrow: "From saved attempts", title: "Progress")

                HStack(alignment: .top, spacing: 14) {
                    metric(value: "\(model.snapshot.attempts.count)", label: "answers recorded")
                    metric(value: accuracyText, label: "attempt accuracy")
                    metric(value: "\(model.progress.filter { $0.status == .demonstrated }.count)", label: "lenses shown")
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("By reasoning lens").font(LensFont.title3.bold()).foregroundStyle(LensTheme.navy)
                    ForEach(model.progress, id: \.objective.id) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.objective.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                                Spacer()
                                Text(item.attemptCount == 0 ? "Not started" : "\(item.correctCount)/\(item.attemptCount) correct")
                                    .font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.slate)
                            }
                            ProgressView(value: item.mastery).tint(item.status == .demonstrated ? LensTheme.success : LensTheme.teal)
                                .accessibilityLabel("\(item.objective.title) mastery estimate")
                                .accessibilityValue("\(Int(item.mastery * 100)) percent")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent learning").font(LensFont.title3.bold()).foregroundStyle(LensTheme.navy)
                    if model.completedSessions.isEmpty {
                        ContentUnavailableView("No completed sessions yet", systemImage: "clock", description: Text("Finish your first focused practice to build a history."))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    } else {
                        ForEach(model.completedSessions.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }.prefix(5)) { session in
                            HStack {
                                Image(systemName: "checkmark.circle").foregroundStyle(LensTheme.success)
                                VStack(alignment: .leading) {
                                    Text(model.content.objective(id: session.objectiveID)?.title ?? "Study session").font(LensFont.subheadline.weight(.semibold))
                                    Text((session.completedAt ?? session.startedAt).formatted(date: .abbreviated, time: .shortened)).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Label("Stored on this device", systemImage: "lock.fill").font(LensFont.headline).foregroundStyle(LensTheme.navy)
                    Link("Review content sources", destination: URL(string: "https://archives.delaware.gov/educator-resources/")!)
                    Button("Reset local progress", role: .destructive) { confirmReset = true }
                }
            }
            .padding(24)
        }
        .background(LensTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset all local progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive, action: model.resetProgress)
            Button("Cancel", role: .cancel) {}
        } message: { Text("This cannot be undone.") }
    }

    private var accuracyText: String { model.accuracy.map { "\(Int(($0 * 100).rounded()))%" } ?? "Not yet" }
    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(LensFont.title2.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
            Text(label).font(LensFont.caption2).foregroundStyle(LensTheme.slate).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
