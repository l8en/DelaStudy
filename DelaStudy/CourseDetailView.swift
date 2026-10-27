import SwiftUI

enum CourseSection: String, CaseIterable { case lessons = "Lessons", resources = "Resources" }

struct CourseDetailView: View {
    @Bindable var model: AppModel
    let course: Course
    @State private var inspecting: CourseImageRecord?
    @State private var activeActivity: StudyActivity?
    @State private var section: CourseSection
    init(model: AppModel, course: Course, section: CourseSection = .lessons) {
        self.model = model; self.course = course; _section = State(initialValue: section)
    }
    private var objectives: [LearningObjective] { model.content.objectives(for: course.id) }
    private var next: LearningObjective? {
        MasteryEngine.recommendation(content: model.content, attempts: model.snapshot.attempts, courseID: course.id)?.objective ?? objectives.first
    }
    private var units: [StudyUnit] { StudyCurriculum.units(for: course.id) }
    private var nextActivity: StudyActivity? {
        StudyCurriculum.nextActivity(for: course.id, workspace: model.snapshot.workspace) ?? units.first?.activities.first
    }
    var body: some View {
        BearingPage(title: course.title.replacingOccurrences(of: " · AP® preparation", with: ""), eyebrow: "\(course.level.title) / \(course.subject.title)") {
            Picker("Course section", selection: $section) {
                Text("Lessons").tag(CourseSection.lessons).accessibilityIdentifier("course-lessons-tab")
                Text("Resources").tag(CourseSection.resources).accessibilityIdentifier("course-resources-tab")
            }.pickerStyle(.segmented).accessibilityIdentifier("course-section")
            if section == .resources {
                CourseResourcesView(model: model, course: course)
            } else {
                if let activity = nextActivity {
                    Button { activeActivity = activity } label: {
                        HStack { Text(model.snapshot.workspace.completedActivityIDs?.contains(activity.id) == true ? "Review lesson" : LessonEntry.activity(activity).wasStarted(in: model.snapshot) ? "Continue lesson" : "Start lesson"); Spacer(); Image(systemName: "arrow.right") }.padding(.horizontal, 16)
                    }.buttonStyle(LensPrimaryButtonStyle()).accessibilityIdentifier("continue-unit-study")
                }
                VStack(spacing: 0) {
                    CourseImageView(courseID: course.id).frame(height: 165).clipShape(RoundedRectangle(cornerRadius: 7))
                    if let record = CourseMedia.image(for: course.id) {
                        Button { inspecting = record } label: {
                            HStack(spacing: 8) {
                                Text(record.title).font(LensFont.caption).lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: "viewfinder").font(LensFont.subheadline)
                            }.foregroundStyle(LensTheme.slate).frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel("Behind the image: \(record.title)")
                            .accessibilityIdentifier("inspect-course-image")
                    }
                }
                Text(course.subtitle).font(LensFont.subheadline).foregroundStyle(LensTheme.slate).lineSpacing(3)
                HStack {
                    Text("\(units.count) units · \(units.flatMap(\.activities).count) activities").font(LensFont.caption)
                    Spacer()
                    Text("\(StudyCurriculum.completedCount(in: units, workspace: model.snapshot.workspace)) studied").font(LensFont.caption.monospacedDigit())
                }.foregroundStyle(LensTheme.slate)
                UnitStudyOutline(model: model, course: course)
                SectionRule(title: "Assessed foundation practice")
                if let next {
                    NavigationLink {
                        LessonDetailView(model: model, course: course, objective: next, lessonNumber: (course.objectiveIDs.firstIndex(of: next.id) ?? 0) + 1)
                    } label: {
                        HStack {
                            Text("Study foundation lesson")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }.padding(.horizontal, 16)
                    }.buttonStyle(LensPrimaryButtonStyle()).accessibilityIdentifier("course-study-next")
                }
                VStack(spacing: 0) {
                    ForEach(Array(objectives.enumerated()), id: \.element.id) { i, objective in
                        let state = model.progress(for: course.id).first { $0.objective.id == objective.id }?.status ?? .ready
                        let locked = state == .locked
                        VStack(alignment: .leading, spacing: 4) {
                            if locked {
                                outlineRow(objective, index: i, state: state)
                                Text("Complete the preceding lesson first.").font(LensFont.caption).foregroundStyle(LensTheme.slate).padding(.leading, 43)
                            } else {
                                NavigationLink { LessonDetailView(model: model, course: course, objective: objective, lessonNumber: i+1) } label: { outlineRow(objective, index: i, state: state) }.buttonStyle(.plain)
                            }
                            Divider().padding(.vertical, 8)
                        }
                    }
                }
                Button(model.selectedCourse.id == course.id ? "Current course" : "Set as current course") { model.selectCourse(course.id) }
                    .font(LensFont.subheadline.weight(.medium)).frame(minHeight: 44).disabled(model.selectedCourse.id == course.id)
            }
        }.sheet(item: $inspecting) { ImageInspectionView(record: $0) }
        .navigationDestination(item: $activeActivity) { activity in
            StudyActivityView(model: model, course: course, activity: activity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { model.toggleSavedCourse(course.id) } label: {
                    Image(systemName: model.snapshot.workspace.savedCourseIDs?.contains(course.id) == true ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44)
                }.accessibilityLabel(model.snapshot.workspace.savedCourseIDs?.contains(course.id) == true ? "Unsave course" : "Save course")
            }
        }
    }
    private func outlineRow(_ objective: LearningObjective, index: Int, state: ObjectiveStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: state == .demonstrated ? "checkmark.circle.fill" : state == .locked ? "lock.circle" : "circle")
                .font(LensFont.subheadline).foregroundStyle(state == .demonstrated ? LensTheme.success : LensTheme.teal)
                .frame(width: 24, height: 36)
            VStack(alignment: .leading, spacing: 5) {
                Text(objective.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                Text(state == .demonstrated ? "Demonstrated" : state == .locked ? "Locked" : state == .review ? "Revisit" : "Ready to study")
                    .font(LensFont.caption).foregroundStyle(LensTheme.slate)
            }
            Spacer()
            Image(systemName: state == .locked ? "lock" : "arrow.up.right").font(LensFont.caption).foregroundStyle(LensTheme.slate)
        }.frame(minHeight: 52)
    }
}

struct StandardsDetailView: View {
    let course: Course
    var body: some View {
        BearingPage(title: "Standards & skills", eyebrow: course.title) {
            let mappings = StandardsRegistry.mappings(for: course)
            if mappings.isEmpty { Text("No Delaware standards mapping has been published for this module.").font(LensFont.subheadline) }
            ForEach(mappings) { mapping in
                VStack(alignment: .leading, spacing: 12) {
                    Text(mapping.id).font(LensFont.headline.monospaced())
                    Text(mapping.status.rawValue).font(LensFont.caption.weight(.semibold)).foregroundStyle(LensTheme.teal)
                    Text(mapping.summary).font(LensFont.subheadline)
                    Text(mapping.rationale).font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
                    Text(mapping.reviewStatus).font(LensFont.caption)
                    Link("Standard source", destination: mapping.sourceURL)
                    Link("Delaware reference", destination: mapping.adoptionURL)
                    Divider()
                }
            }
            Text("Mappings describe selected activities. They do not imply state approval or full curriculum coverage.").font(LensFont.caption).foregroundStyle(LensTheme.slate)
        }
    }
}
