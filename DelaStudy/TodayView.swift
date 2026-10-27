import SwiftUI

struct TodayView: View {
    @Bindable var model: AppModel
    @State private var offset: CGFloat = 0
    @State private var addingTask: PersonalTask?
    @State private var studyRoute: StudyRoute?
    @State private var intake: MaterialIntake?
    @State private var academicSetup = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var studyUnits: [StudyUnit] { StudyCurriculum.units(for: model.selectedCourse.id) }
    private var nextStudy: StudyActivity? {
        StudyCurriculum.nextActivity(for: model.selectedCourse.id, workspace: model.snapshot.workspace) ?? studyUnits.first?.activities.first
    }
    private var next: LearningObjective? {
        MasteryEngine.recommendation(content: model.content, attempts: model.snapshot.attempts, courseID: model.selectedCourse.id)?.objective
            ?? model.content.objectives(for: model.selectedCourse.id).first
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LensScrollMarker()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                            .font(LensFont.caption2.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.slate)
                        Text("Today").font(LensFont.system(.title, weight: .bold)).tracking(-0.7)
                    }
                    Spacer()
                    profileLink.accessibilityHidden(offset < -90)
                }.opacity(max(0, 1 + offset/120))
                currentStudy
                studyDesk
                MaterialIntakeGrid { intake = $0 }
                NavigationLink { MaterialsView(model: model) } label: {
                    HStack {
                        Text("My materials").font(LensFont.subheadline.weight(.semibold))
                        Text("\(model.studyMaterials.count)").font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.slate)
                        Spacer(); Image(systemName: "arrow.right")
                    }.frame(minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("open-materials")
                if model.snapshot.workspace.academicSetupComplete != true {
                    Button { academicSetup = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3").foregroundStyle(LensTheme.teal)
                            Text("Set your year, route & school").font(LensFont.subheadline.weight(.semibold))
                            Spacer(); Image(systemName: "arrow.up.right")
                        }.padding(14).frame(minHeight: 52).background(LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(LensCardButtonStyle()).accessibilityIdentifier("open-study-setup")
                }
                HStack(spacing: 10) {
                    NavigationLink { FocusView(model: model, initialTask: nextStudy?.title ?? next?.title ?? model.selectedCourse.title, objectiveID: nextStudy == nil ? next?.id : nil) } label: {
                        quickAction("timer", "Focus", model.snapshot.workspace.focus == nil ? "\(model.todayStudyMinutes)/\(model.snapshot.profile.dailyGoalMinutes) min today" : "Session active")
                    }
                    NavigationLink { ReviewHubView(model: model) } label: {
                        quickAction("arrow.counterclockwise", "Review", "\(model.reviewQuestions.count) to revisit")
                    }
                }.buttonStyle(LensCardButtonStyle())
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Agenda").font(LensFont.headline)
                        Spacer()
                        Button { addingTask = PersonalTask(title: model.snapshot.workspace.plannerDraft ?? "") } label: {
                            Image(systemName: "plus").frame(width: 44, height: 44)
                        }.accessibilityLabel("Add study task")
                    }
                    let tasks = WorkspaceEngine.sortedTasks(model.snapshot.workspace.tasks).filter { !$0.isComplete }
                    if tasks.isEmpty {
                        Button { addingTask = PersonalTask(title: "") } label: {
                            HStack {
                                Image(systemName: "plus.circle").foregroundStyle(LensTheme.teal)
                                Text("Add a study task").font(LensFont.subheadline)
                                Spacer()
                                Image(systemName: "arrow.up.right").font(LensFont.caption)
                            }.padding(.vertical, 10)
                        }.buttonStyle(.plain)
                    }
                    ForEach(tasks.prefix(3)) { task in
                        PlannerTaskRow(model: model, task: task, edit: { addingTask = task })
                        Divider()
                    }
                    NavigationLink("Open planner") { PlannerView(model: model) }.font(LensFont.caption.weight(.semibold)).frame(minHeight: 44)
                }
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LEARNING RECORD").font(LensFont.caption2.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.slate)
                        Text("\(model.completedSessions.count) practice \(model.completedSessions.count == 1 ? "session" : "sessions")").font(LensFont.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("\(model.stats.xp) XP").font(LensFont.subheadline.monospacedDigit().weight(.semibold)).foregroundStyle(LensTheme.teal)
                }.padding(.top, 4)
                weekStrip
            }.padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 24)
        }.background(LensTheme.paper).foregroundStyle(LensTheme.navy)
            .lensScrollSpace { offset = min(0, $0) }
            .morphingTopBar(title: "Today", symbol: "", collapsed: offset < -90)
            .toolbar(offset < -90 ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                if offset < -90 { profileToolbar }
            }
            .sheet(item: $addingTask) { TaskEditor(model: model, original: $0) }
            .sheet(item: $intake) { MaterialImportView(model: model, intake: $0) }
            .sheet(isPresented: $academicSetup) { StudySetupView(model: model) }
            .navigationDestination(item: $studyRoute) { route in
                StudyActivityView(model: model, course: route.course, activity: route.activity)
            }
    }
    private var studyDesk: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0)) : AnyLayout(HStackLayout(spacing: 5))
        let goal = max(1, model.snapshot.profile.dailyGoalMinutes)
        let remaining = max(0, goal - model.todayStudyMinutes)
        let progress = min(1, Double(model.todayStudyMinutes) / Double(goal))
        return NavigationLink { FocusView(model: model, initialTask: nextStudy?.title ?? model.selectedCourse.title) } label: {
            layout {
                LensCoreView(progress: progress, active: false, controls: false, contextLabel: "Daily Focus goal")
                    .frame(width: typeSize.isAccessibilitySize ? 110 : 130, height: 130).allowsHitTesting(false)
                    .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.86), value: progress)
                VStack(alignment: .leading, spacing: 6) {
                    Text("DAILY FOCUS").font(LensFont.caption2.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.lime)
                    Text(remaining == 0 ? "Goal reached" : "\(remaining) min to go").font(LensFont.title2.weight(.bold)).foregroundStyle(.white)
                    Text("\(model.todayStudyMinutes) of \(goal) minutes saved").font(LensFont.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.84))
                    HStack { Text(model.snapshot.workspace.focus == nil ? "Start a session" : "Resume session"); Image(systemName: "arrow.right") }.font(LensFont.subheadline.weight(.semibold)).foregroundStyle(.white).padding(.top, 7)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding(14).frame(maxWidth: .infinity, alignment: .leading).background(LensTheme.midnight, in: RoundedRectangle(cornerRadius: 24))
        }.buttonStyle(LensCardButtonStyle()).accessibilityLabel("Daily Focus: \(model.todayStudyMinutes) of \(goal) minutes. Open Focus session.").accessibilityIdentifier("daily-focus-lens")
    }
    private var currentStudy: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 7) {
                Circle().fill(LensTheme.teal).frame(width: 5, height: 5)
                Text("YOUR NEXT LESSON").font(LensFont.caption2.weight(.medium)).tracking(0.8)
                Spacer()
                NavigationLink("Course outline") { CourseDetailView(model: model, course: model.selectedCourse) }
                    .font(LensFont.caption.weight(.semibold)).frame(minHeight: 44).accessibilityIdentifier("lesson-course-outline")
            }
            HStack(alignment: .top, spacing: 17) {
                NavigationLink {
                    CourseDetailView(model: model, course: model.selectedCourse)
                } label: {
                    CourseImageView(courseID: model.selectedCourse.id)
                        .frame(width: 76, height: 90).clipShape(RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(LensCardButtonStyle()).accessibilityLabel("Open \(model.selectedCourse.title)")
                VStack(alignment: .leading, spacing: 7) {
                    Text(model.selectedCourse.title.replacingOccurrences(of: " · AP® preparation", with: ""))
                        .font(LensFont.caption.weight(.medium)).foregroundStyle(LensTheme.teal).fixedSize(horizontal: false, vertical: true)
                    if let nextStudy { Text(nextStudy.title).font(LensFont.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true) }
                    else if let next { Text(next.title).font(LensFont.subheadline).foregroundStyle(LensTheme.slate).fixedSize(horizontal: false, vertical: true) }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 3)
            }
            if let nextStudy {
                Button { studyRoute = StudyRoute(course: model.selectedCourse, activity: nextStudy) } label: {
                    HStack {
                        Text(model.snapshot.workspace.completedActivityIDs?.contains(nextStudy.id) == true ? "Review lesson" : LessonEntry.activity(nextStudy).wasStarted(in: model.snapshot) ? "Continue lesson" : "Start lesson")
                        Spacer(); Image(systemName: "arrow.right")
                    }.padding(.horizontal, 16)
                }.buttonStyle(LensPrimaryButtonStyle()).accessibilityIdentifier("continue-unit-study-home")
            } else {
                NavigationLink { CourseDetailView(model: model, course: model.selectedCourse) } label: {
                    Text("Review unit studies").frame(maxWidth: .infinity)
                }.buttonStyle(LensPrimaryButtonStyle())
            }
            Rectangle().fill(LensTheme.border).frame(height: 1).padding(.top, 3)
        }
    }
    @ToolbarContentBuilder private var profileToolbar: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarTrailing) { profileLink }.sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarTrailing) { profileLink }
        }
    }
    private var profileLink: some View {
        NavigationLink { ProfileView(model: model) } label: {
            LearnerAvatar(model: model, size: 40).frame(width: 44, height: 44).contentShape(Circle())
        }.buttonStyle(.plain).accessibilityLabel("Your profile").accessibilityIdentifier("open-profile")
    }
    private func quickAction(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(LensFont.system(size: 18, weight: .medium)).foregroundStyle(LensTheme.teal)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                Text(detail).font(LensFont.caption).foregroundStyle(LensTheme.slate)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 10).frame(maxWidth: .infinity, minHeight: 62)
    }
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { i in
                let date = Calendar.current.date(byAdding: .day, value: i-6, to: .now)!
                let count = model.completedSessions.filter { Calendar.current.isDate($0.completedAt ?? .distantPast, inSameDayAs: date) }.count
                VStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 3).fill(count > 0 ? LensTheme.teal : LensTheme.border)
                        .frame(height: CGFloat(8+min(5, count)*5)).frame(height: 34, alignment: .bottom)
                    Text(date, format: .dateTime.weekday(.narrow)).font(LensFont.caption2).foregroundStyle(LensTheme.slate)
                }.frame(maxWidth: .infinity).padding(.horizontal, 5)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(count) practice sessions")
            }
        }
    }
}
