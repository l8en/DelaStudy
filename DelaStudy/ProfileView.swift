import SwiftUI

struct ProfileView: View {
    @Bindable var model: AppModel
    @State private var editing = false
    @State private var photoEditing = false
    @State private var settings = false
    @State private var name = ""
    @State private var goal = 10
    @State private var banner = "mathematics"
    @State private var section = "Record"
    @State private var academicSetup = false
    @Environment(\.dynamicTypeSize) private var typeSize
    private var subject: CourseSubject { CourseSubject(rawValue: model.snapshot.workspace.banner) ?? .mathematics }
    private var bannerCourse: Course {
        let covers: [CourseSubject: String] = [.history: "first-state-civics", .mathematics: "geometry", .biology: "general-biology",
            .chemistry: "prep-chemistry", .physics: "high-school-physics", .english: "writing-rhetoric",
            .socialScience: "macroeconomics", .computerScience: "prep-computer-science-a", .finance: "personal-finance"]
        return model.content.course(id: covers[subject] ?? "") ?? model.selectedCourse
    }
    var body: some View {
        BearingPage(title: "Profile", eyebrow: "Level \(model.stats.level)") {
            VStack(spacing: 0) {
                CourseImageView(courseID: bannerCourse.id).frame(height: 125)
                identity.padding(16)
                let progressLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())
                progressLayout {
                    Text("\(model.stats.xp % 100) / 100 XP")
                    if !typeSize.isAccessibilitySize { Spacer() }
                    Text("Next · Level \(model.stats.level + 1)")
                }.font(LensFont.caption.monospacedDigit()).padding(.horizontal, 16).padding(.bottom, 16)
            }.background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 16)).clipShape(RoundedRectangle(cornerRadius: 16))
            academicContext
            HStack(spacing: 12) {
                NavigationLink { ActivityComposerView(model: model) } label: {
                    Label("Invite to study", systemImage: "person.badge.plus").font(LensFont.subheadline.weight(.semibold))
                        .padding(.horizontal, 18).frame(minHeight: 46).foregroundStyle(LensTheme.onInk).background(LensTheme.navy, in: Capsule())
                }
                NavigationLink { LearningSummaryView(model: model) } label: {
                    Image(systemName: "square.and.arrow.up").frame(width: 46, height: 46).background(LensTheme.surface, in: Circle())
                }.accessibilityLabel("Share selected progress")
                Spacer(minLength: 0)
            }.buttonStyle(LensCardButtonStyle())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(["Record", "Stats", "Materials", "School"], id: \.self) { title in
                        Button { section = title } label: {
                            VStack(spacing: 10) {
                                Text(title).font(LensFont.subheadline.weight(section == title ? .bold : .medium)).foregroundStyle(section == title ? LensTheme.navy : LensTheme.slate)
                                Capsule().fill(section == title ? LensTheme.teal : .clear).frame(height: 3)
                            }.frame(minHeight: 44)
                        }.buttonStyle(.plain).accessibilityAddTraits(section == title ? [.isSelected] : []).accessibilityIdentifier("profile-tab-\(title)")
                    }
                }
            }
            if section == "Record" {
            HStack {
                SectionRule(title: "Achievements")
                NavigationLink("See all") { AwardsView(model: model) }.font(LensFont.caption.weight(.semibold)).frame(minHeight: 44)
            }
            let featured = model.awards.filter { $0.isUnlocked && model.snapshot.workspace.featuredAwardIDs.contains($0.id) }
            let display = featured.isEmpty ? Array(model.awards.prefix(3)) : Array(featured.prefix(3))
            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(display.enumerated()), id: \.element.id) { index, award in
                    NavigationLink { AwardDetailView(model: model, award: award, index: index) } label: {
                        VStack(spacing: 8) {
                            AchievementGlyph(index: index, earned: award.isUnlocked).frame(height: 76)
                            Text(award.title).font(LensFont.caption.weight(.medium)).foregroundStyle(LensTheme.navy).multilineTextAlignment(.center)
                            Text(award.isUnlocked ? "Earned" : "\(award.current)/\(award.target)").font(LensFont.caption2.monospacedDigit()).foregroundStyle(LensTheme.slate)
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(LensCardButtonStyle())
                }
            }.padding(14).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            if section == "Stats" {
            SectionRule(title: "Learning record")
            let recordLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout())
            recordLayout {
                metric("\(model.completedSessions.count)", "Sessions")
                metric("\(model.progress.filter { $0.status == .demonstrated }.count)", "Skills shown")
                metric("\((model.snapshot.workspace.completedActivityIDs ?? []).intersection(StudyCurriculum.activityIDs).count)", "Activities studied")
            }.padding(.vertical, 10)
                StudyWeekChart(model: model)
                let focusLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout())
                focusLayout {
                    metric("\(model.todayStudyMinutes)", "Focus minutes today")
                    metric("\(model.snapshot.workspace.focusHistory.count)", "Saved Focus intervals")
                }
                NavigationLink { ProgressViewScreen(model: model) } label: { WorkspaceRow(symbol: "chart.xyaxis.line", title: "Skills & practice record") }
                NavigationLink { LearningSummaryView(model: model) } label: { WorkspaceRow(symbol: "square.and.arrow.up", title: "Share selected progress") }
            }
            if section == "Materials" {
                NavigationLink { MaterialsView(model: model) } label: { WorkspaceRow(symbol: "plus", title: "Add study material") }
                MaterialList(model: model)
            }
            if section == "School" {
                Button { academicSetup = true } label: { WorkspaceRow(symbol: "slider.horizontal.3", title: "Edit year, route & school") }.buttonStyle(.plain)
                NavigationLink { SchoolWorkspaceView(model: model) } label: { WorkspaceRow(symbol: "mappin", title: "School & academic goals") }
                NavigationLink { CollegeHubView(model: model) } label: { WorkspaceRow(symbol: "building.columns", title: "College & career planning") }
            SectionRule(title: "Interests")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 115))], alignment: .leading, spacing: 8) {
                ForEach(CourseSubject.allCases, id: \.self) { subject in
                    let selected = model.snapshot.workspace.interests.contains(subject.rawValue)
                    Button {
                        model.updateWorkspace { w in
                            if selected { w.interests.remove(subject.rawValue) } else { w.interests.insert(subject.rawValue) }
                        }
                    } label: {
                        Text(subject.title).font(LensFont.caption.weight(.medium)).foregroundStyle(selected ? LensTheme.onInk : LensTheme.navy)
                            .padding(.horizontal, 12).frame(maxWidth: .infinity, minHeight: 44)
                            .background(selected ? LensTheme.navy : LensTheme.surface, in: RoundedRectangle(cornerRadius: 9))
                    }.buttonStyle(.plain).accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            }
            if section == "Record" && !model.completedSessions.isEmpty {
                SectionRule(title: "Recent work")
                ForEach(model.completedSessions.reversed().prefix(4)) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.content.objective(id: session.objectiveID)?.title ?? "Practice").font(LensFont.subheadline.weight(.medium))
                            Text(session.completedAt ?? session.startedAt, style: .date).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle").foregroundStyle(LensTheme.success)
                    }.padding(.vertical, 6)
                }
            }
        }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { settings = true } label: { Image(systemName: "gearshape").frame(width: 44, height: 44) }.accessibilityLabel("Settings").accessibilityIdentifier("open-settings") } }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView(model: model).toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { settings = false } } } } }
        .sheet(isPresented: $academicSetup) { StudySetupView(model: model) }
        .sheet(isPresented: $editing) {
            NavigationStack {
                Form {
                    TextField("Name", text: $name)
                    Picker("Daily focus goal", selection: $goal) { ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) minutes").tag($0) } }
                    Picker("Collection image", selection: $banner) { ForEach(CourseSubject.allCases, id: \.self) { Text($0.title).tag($0.rawValue) } }
                }.navigationTitle("Edit profile").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("Save") { if model.updateProfile(name: name, dailyGoalMinutes: goal, banner: banner) { editing = false } } }
                    }
            }.presentationDetents([.large])
        }
        .sheet(isPresented: $photoEditing) {
            NavigationStack {
                Form { ProfilePhotoEditor(model: model) }.navigationTitle("Profile photo").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { photoEditing = false } } }
            }
        }
    }
    private var academicContext: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let school = SchoolDirectory.schools.first(where: { $0.id == model.snapshot.workspace.schoolID }) {
                Text(school.name).font(LensFont.subheadline.weight(.semibold))
            }
            let context = [model.snapshot.workspace.academicYear, model.snapshot.workspace.studyRoute?.title].compactMap { $0 }.joined(separator: " · ")
            if !context.isEmpty { Text(context).font(LensFont.caption).foregroundStyle(LensTheme.slate) }
            if context.isEmpty { Button("Set your year, route & school") { academicSetup = true }.font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder private var identity: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 16) {
                HStack { photoAction; Spacer(); editAction }
                identityDetails
            }.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 14) { photoAction; identityDetails; Spacer(); editAction }
        }
    }
    private var photoAction: some View {
        Button { photoEditing = true } label: {
            LearnerAvatar(model: model).overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera.fill").font(LensFont.system(size: 12, weight: .semibold)).padding(7)
                    .foregroundStyle(LensTheme.onInk).background(LensTheme.navy, in: Circle())
            }
        }.buttonStyle(.plain).accessibilityLabel("Edit profile photo").accessibilityIdentifier("edit-profile-photo")
    }
    private var identityDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.snapshot.profile.displayName).font(LensFont.title3.weight(.semibold))
            if let username = model.identity.username, username != model.snapshot.profile.displayName {
                Text("@\(username)").font(LensFont.caption).foregroundStyle(LensTheme.teal)
            }
            Text("LEVEL \(model.stats.level)").font(LensFont.caption.weight(.semibold)).foregroundStyle(LensTheme.teal)
            Text("\(model.stats.xp) XP · \(model.stats.streakDays)-day practice streak").font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.slate)
        }
    }
    private var editAction: some View {
        Button {
            name = model.snapshot.profile.displayName; goal = model.snapshot.profile.dailyGoalMinutes
            banner = model.snapshot.workspace.banner; editing = true
        } label: { Image(systemName: "pencil").frame(width: 44, height: 44) }.accessibilityLabel("Edit profile")
    }
    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(LensFont.title2.monospacedDigit().weight(.semibold))
            Text(label).font(LensFont.caption).foregroundStyle(LensTheme.slate)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StudyWeekChart: View {
    @Bindable var model: AppModel
    private var dates: [Date] { (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0 - 6, to: .now) } }
    private func count(_ date: Date) -> Int { model.completedSessions.filter { Calendar.current.isDate($0.completedAt ?? .distantPast, inSameDayAs: date) }.count }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Practice · last 7 days").font(LensFont.subheadline.weight(.semibold))
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    let value = count(date), maximum = max(1, dates.map(count).max() ?? 1)
                    VStack(spacing: 8) {
                        Text("\(value)").font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.slate)
                        RoundedRectangle(cornerRadius: 5).fill(value == 0 ? LensTheme.border : LensTheme.teal)
                            .frame(height: max(3, Double(value) / Double(maximum) * 65)).frame(height: 65, alignment: .bottom)
                        Text(date, format: .dateTime.weekday(.narrow)).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(value) practice sessions")
                }
            }
        }.padding(16).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
