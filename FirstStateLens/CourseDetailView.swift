import SwiftUI

struct CourseDetailView: View {
    @Bindable var model: AppModel
    let course: Course
    private var color: Color { LensTheme.courseColor(course.subject) }
    private var objectives: [LearningObjective] { model.content.objectives(for: course.id) }
    private var progress: [ObjectiveProgress] { model.progress(for: course.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                VStack(alignment: .leading, spacing: 0) {
                    Text("COURSE PATH").font(.caption.bold()).tracking(1.2).foregroundStyle(color).padding(.bottom, 16)
                    ForEach(Array(objectives.enumerated()), id: \.element.id) { index, objective in lessonRow(objective, index: index) }
                }
                curriculumPanel
                SourceNote(source: course.source)
            }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 30)
        }
        .background(LensTheme.paper).navigationTitle(course.title).navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Image(systemName: course.symbolName).font(.system(size: 34, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 72, height: 72).background(color, in: RoundedRectangle(cornerRadius: 22))
                Spacer()
                Text("\(Int(model.courseCompletion(course.id) * 100))%").font(.title2.monospacedDigit().bold()).foregroundStyle(color)
            }
            Text("\(course.level.title) · \(course.subject.title)".uppercased()).font(.caption.bold()).tracking(1.2).foregroundStyle(color)
            Text(course.title).font(.system(.largeTitle, design: .rounded, weight: .heavy)).foregroundStyle(LensTheme.navy)
            Text(course.subtitle).font(.headline).foregroundStyle(LensTheme.navy).lineSpacing(3)
            ProgressView(value: model.courseCompletion(course.id)).tint(color)
            if let nextObjective {
                NavigationLink {
                    LessonDetailView(model: model, course: course, objective: nextObjective, lessonNumber: max(1, objectives.firstIndex(of: nextObjective).map { $0 + 1 } ?? 1))
                } label: { Text(courseButtonTitle) }
                .buttonStyle(LensPrimaryButtonStyle())
                .simultaneousGesture(TapGesture().onEnded { model.selectCourse(course.id) })
            }
        }
        .padding(22).background(LensTheme.courseSurface(course.subject), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var nextObjective: LearningObjective? {
        MasteryEngine.recommendation(content: model.content, attempts: model.snapshot.attempts, courseID: course.id)?.objective ?? objectives.first
    }

    private var curriculumPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CURRICULUM").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
            Text(course.curriculum.title).font(.headline).foregroundStyle(LensTheme.navy)
            Text(course.curriculum.provider).font(.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
            Link(destination: course.curriculum.url) { Label("Open curriculum", systemImage: "arrow.up.right") }.font(.subheadline.weight(.bold)).foregroundStyle(LensTheme.navy)
        }
        .padding(18).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var courseButtonTitle: String {
        if model.courseCompletion(course.id) >= 1 { return "Review course" }
        return model.selectedCourse.id == course.id ? "Continue course" : "Make this my course"
    }

    @ViewBuilder private func lessonRow(_ objective: LearningObjective, index: Int) -> some View {
        let status = progress.first { $0.objective.id == objective.id }?.status ?? .locked
        let accessible = status != .locked
        if accessible {
            NavigationLink {
                LessonDetailView(model: model, course: course, objective: objective, lessonNumber: index + 1)
            } label: { lessonRowContent(objective, index: index, status: status, accessible: true) }
            .buttonStyle(.plain)
            .accessibilityLabel("Lesson \(index + 1), \(objective.title), \(statusLabel(status))")
        } else {
            lessonRowContent(objective, index: index, status: status, accessible: false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lesson \(index + 1), \(objective.title), locked")
        }
    }

    private func lessonRowContent(_ objective: LearningObjective, index: Int, status: ObjectiveStatus, accessible: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Image(systemName: statusSymbol(status)).font(.headline).foregroundStyle(accessible ? .white : LensTheme.slate)
                    .frame(width: 46, height: 46).background(accessible ? LensTheme.navy : LensTheme.border, in: Circle())
                if index < objectives.count - 1 { Rectangle().fill(status == .demonstrated ? color : LensTheme.border).frame(width: 3, height: 54) }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("LESSON \(index + 1) · \(statusLabel(status).uppercased())").font(.caption2.bold()).tracking(1).foregroundStyle(accessible ? color : LensTheme.slate)
                Text(objective.title).font(.headline).foregroundStyle(accessible ? LensTheme.navy : LensTheme.slate)
            }.padding(.top, 3)
            Spacer(minLength: 0)
        }
    }

    private func statusSymbol(_ status: ObjectiveStatus) -> String {
        switch status { case .locked: "lock.fill"; case .ready: "play.fill"; case .learning: "arrow.triangle.2.circlepath"; case .review: "arrow.clockwise"; case .demonstrated: "checkmark" }
    }
    private func statusLabel(_ status: ObjectiveStatus) -> String {
        switch status { case .locked: "Locked"; case .ready: "Ready"; case .learning: "Learning"; case .review: "Review"; case .demonstrated: "Complete" }
    }
}
