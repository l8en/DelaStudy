import SwiftUI

struct StudySetupView: View {
    @Bindable var model: AppModel
    var required = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var draft = StudentSetupDraft()
    @State private var loaded = false
    @State private var pickingSchool = false
    @State private var direction = 1
    private var stage: SetupStage { draft.stage }
    private var courses: [Course] { StudentSetupEngine.courses(for: draft, content: model.content) }
    private var startingCourse: Course? { courses.first { $0.id == draft.courseID } ?? courses.first }
    private var schoolName: String { SchoolDirectory.schools.first { $0.id == draft.schoolID }?.name ?? (draft.schoolID == "home" ? "Home study" : draft.schoolID == "outside" ? "Outside Delaware" : "School is optional") }
    private var selectionSummary: String {
        switch stage {
        case .year: draft.year ?? "Choose your year"
        case .aim: draft.aim?.title ?? draft.year ?? "Your main goal"
        case .subjects: "\(draft.subjects.count) selected"
        case .route: draft.route.title
        case .school: schoolName
        case .rhythm: "\(draft.workMinutes) min work · \(draft.breakMinutes) min break"
        case .ready: ""
        }
    }
    private var title: String {
        switch stage {
        case .year: "Where are you starting?"
        case .aim: "What brings you here?"
        case .subjects: "Make room for your subjects."
        case .route: "Choose your direction."
        case .school: "Bring your school with you."
        case .rhythm: "Find a rhythm you can keep."
        case .ready: "Your lens is ready."
        }
    }
    var body: some View {
        NavigationStack {
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Color.clear.frame(height: 1).id("setup-top")
                        HStack(spacing: 6) { ForEach(SetupStage.allCases, id: \.self) { item in Capsule().fill(item.index <= stage.index ? LensTheme.teal : LensTheme.border).frame(height: 5) } }
                            .accessibilityElement(children: .ignore).accessibilityLabel("\(stage.title), step \(stage.index + 1) of \(SetupStage.allCases.count)")
                        if stage == .ready { SetupLensPreview(draft: draft).frame(height: 160) }
                        else {
                            HStack(spacing: 15) {
                                SetupLensPreview(draft: draft, compact: true).frame(width: 76, height: 80)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(stage.title.uppercased()).font(LensFont.caption.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.teal)
                                    Text(selectionSummary).font(LensFont.subheadline.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        Text(title).font(LensFont.system(.largeTitle, weight: .bold)).tracking(-1).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                        stageContent.id(stage).transition(reduceMotion ? .opacity : .asymmetric(insertion: .opacity.combined(with: .offset(x: direction > 0 ? 20 : -20)), removal: .opacity))
                    }.padding(.horizontal, 22).padding(.bottom, 20)
                }.scrollDismissesKeyboard(.interactively).background(LensTheme.paper).foregroundStyle(LensTheme.navy)
                    .safeAreaInset(edge: .bottom, spacing: 0) { nextAction }
                    .navigationBarTitleDisplayMode(.inline).navigationTitle("Your study lens")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            if stage != .year { Button("Back") { advance(-1) }.accessibilityIdentifier("setup-back") }
                            else if !required { Button("Cancel") { dismiss() } }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            if required { Menu { Button("Sign out", action: model.signOut) } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel("Setup account options") }
                        }
                    }
                    .onAppear {
                        guard !loaded else { return }; loaded = true
                        draft = required ? model.snapshot.workspace.studentSetup ?? StudentSetupDraft(snapshot: model.snapshot, initial: true) : StudentSetupDraft(snapshot: model.snapshot, initial: false)
                    }
                    .onChange(of: stage) { _, _ in reader.scrollTo("setup-top", anchor: .top) }
            }
            .sheet(isPresented: $pickingSchool) { NavigationStack { SchoolPickerView(model: model, selectedSchoolID: draft.schoolID, onSelect: { value in change { $0.schoolID = value } }) } }
        }
    }
    @ViewBuilder private var stageContent: some View {
        switch stage {
        case .year:
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(StudentSetupDraft.years, id: \.self) { year in tile(year, symbol: year == "College" ? "building.columns" : "graduationcap", selected: draft.year == year) { change { $0.year = year; if year == "College" { $0.route = .college } } } }
            }
        case .aim:
            LazyVGrid(columns: columns, spacing: 12) { ForEach(StudyAim.allCases, id: \.self) { aim in tile(aim.title, symbol: aim.symbol, selected: draft.aim == aim) { change { $0.aim = aim } } } }
        case .subjects:
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CourseSubject.allCases, id: \.self) { subject in
                    tile(subject.title, symbol: subjectSymbol(subject), selected: draft.subjects.contains(subject.rawValue), tint: LensTheme.courseColor(subject)) {
                        change { if !$0.subjects.insert(subject.rawValue).inserted { $0.subjects.remove(subject.rawValue) }; $0.courseID = nil }
                    }
                }
            }
        case .route:
            VStack(spacing: 10) {
                ForEach(AcademicRoute.allCases, id: \.self) { route in selectionRow(route.title, selected: draft.route == route) { change { $0.route = route; $0.courseID = nil } } }
                Text(draft.route.detail).font(LensFont.caption).foregroundStyle(LensTheme.slate).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 2)
            }
        case .school:
            VStack(alignment: .leading, spacing: 16) {
                if draft.schoolID != nil { Label(schoolName, systemImage: "building.2").font(LensFont.headline).accessibilityIdentifier("setup-school-name") }
                Button { pickingSchool = true } label: {
                    HStack { Image(systemName: "magnifyingglass"); Text("Search Delaware schools"); Spacer(); Image(systemName: "arrow.right") }
                        .font(LensFont.subheadline.weight(.semibold)).padding(18).frame(minHeight: 58).background(LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(LensCardButtonStyle()).accessibilityIdentifier("setup-find-school")
                selectionRow("Home study", selected: draft.schoolID == "home") { change { $0.schoolID = "home" } }
                selectionRow("Outside Delaware", selected: draft.schoolID == "outside") { change { $0.schoolID = "outside" } }
                selectionRow("Keep my school private", selected: draft.schoolID == nil) { change { $0.schoolID = nil } }
                Text("Private by default. No location or enrollment verification.").font(LensFont.caption).foregroundStyle(LensTheme.slate)
            }
        case .rhythm:
            VStack(alignment: .leading, spacing: 22) {
                Text("Daily focus goal").font(LensFont.headline)
                if typeSize.isAccessibilitySize {
                    LazyVGrid(columns: columns, spacing: 10) { ForEach([5, 10, 15, 20, 30], id: \.self) { minutes in selectionRow("\(minutes) minutes", selected: draft.dailyMinutes == minutes) { change { $0.dailyMinutes = minutes } } } }
                } else {
                    HStack(spacing: 8) {
                        ForEach([5, 10, 15, 20, 30], id: \.self) { minutes in
                            Button { change { $0.dailyMinutes = minutes } } label: {
                                VStack(spacing: 3) { Text("\(minutes)").font(LensFont.title3.weight(.bold)); Text("min").font(LensFont.caption2) }
                                    .frame(maxWidth: .infinity, minHeight: 65)
                                    .foregroundStyle(draft.dailyMinutes == minutes ? LensTheme.onInk : LensTheme.navy)
                                    .background(draft.dailyMinutes == minutes ? LensTheme.navy : LensTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                            }.buttonStyle(LensCardButtonStyle()).accessibilityLabel("\(minutes) minutes").accessibilityAddTraits(draft.dailyMinutes == minutes ? .isSelected : [])
                        }
                    }
                }
                Text("Work / break").font(LensFont.headline)
                HStack(spacing: 12) {
                    tile("25 / 5", symbol: "timer", selected: draft.workMinutes == 25 && draft.breakMinutes == 5) { change { $0.workMinutes = 25; $0.breakMinutes = 5 } }
                    tile("50 / 10", symbol: "timer", selected: draft.workMinutes == 50 && draft.breakMinutes == 10) { change { $0.workMinutes = 50; $0.breakMinutes = 10 } }
                }
                Text("Starting atmosphere").font(LensFont.headline)
                LazyVGrid(columns: columns, spacing: 10) { ForEach(StudySound.allCases, id: \.self) { sound in selectionRow(sound.title, selected: draft.sound == sound) { change { $0.sound = sound } } } }
            }
        case .ready: readyPlan
        }
    }
    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2) }
    private var readyPlan: some View {
        VStack(alignment: .leading, spacing: 18) {
            let summaryLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .top))
            summaryLayout {
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.aim?.title ?? "Your next step").font(LensFont.headline)
                    Text("\(draft.year ?? "") · \(draft.route.title)").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                }
                if !typeSize.isAccessibilitySize { Spacer() }
                Text(typeSize.isAccessibilitySize ? "\(draft.dailyMinutes) min / day" : "\(draft.dailyMinutes)\nmin / day").font(LensFont.subheadline.monospacedDigit().weight(.semibold)).foregroundStyle(LensTheme.teal).multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
            }
            if let course = startingCourse {
                let courseLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))
                courseLayout {
                    CourseImageView(courseID: course.id).frame(width: 88, height: 96).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 7) {
                        Text("START HERE").font(LensFont.caption2.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.teal)
                        Text(course.title).font(LensFont.headline)
                        Text("5 units · 30 activities").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    }
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                Picker("Starting course", selection: Binding(get: { startingCourse?.id ?? "" }, set: { id in change { $0.courseID = id } })) { ForEach(courses) { Text($0.title).tag($0.id) } }.pickerStyle(.menu).font(LensFont.subheadline)
            }
            Toggle("Add my first study task", isOn: Binding(get: { draft.addFirstTask }, set: { value in change { $0.addFirstTask = value } })).font(LensFont.subheadline)
            ViewThatFits(in: .horizontal) {
                HStack { Label("\(draft.workMinutes) min work", systemImage: "timer"); Spacer(); Label(draft.sound.title, systemImage: "waveform") }
                VStack(alignment: .leading, spacing: 8) { Label("\(draft.workMinutes) min work", systemImage: "timer"); Label(draft.sound.title, systemImage: "waveform") }
            }.font(LensFont.caption).foregroundStyle(LensTheme.slate)
        }
    }
    private var nextAction: some View {
        Button(stage == .ready ? required ? "Open my desk" : "Save preferences" : "Continue") {
            if stage == .ready { if model.finishStudentSetup(draft) && !required { dismiss() } }
            else { advance(1) }
        }.buttonStyle(LensPrimaryButtonStyle()).disabled(!draft.canContinue).accessibilityIdentifier("setup-continue")
            .padding(.horizontal, 22).padding(.vertical, 12).background(LensTheme.paper)
    }
    private func advance(_ delta: Int) {
        let index = max(0, min(SetupStage.allCases.count - 1, stage.index + delta)); direction = delta
        change { $0.stage = SetupStage.allCases[index] }
    }
    private func change(_ update: (inout StudentSetupDraft) -> Void) {
        var next = draft; update(&next)
        guard !required || model.saveStudentSetup(next) else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.88)) { draft = next }
    }
    private func tile(_ title: String, symbol: String, selected: Bool, tint: Color = LensTheme.teal, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Image(systemName: symbol).font(LensFont.title3).foregroundStyle(selected ? LensTheme.onInk : tint); Spacer(); if selected { Image(systemName: "checkmark").font(LensFont.caption.weight(.bold)).foregroundStyle(LensTheme.onInk) } }
                Text(title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(selected ? LensTheme.onInk : LensTheme.navy).fixedSize(horizontal: false, vertical: true)
            }.padding(16).frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
                .background(selected ? LensTheme.navy : LensTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? LensTheme.navy : LensTheme.border, lineWidth: 1))
        }.buttonStyle(LensCardButtonStyle()).accessibilityLabel(title).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func selectionRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack { Text(title).font(LensFont.subheadline.weight(.semibold)); Spacer(); Image(systemName: selected ? "checkmark.circle.fill" : "circle").foregroundStyle(selected ? LensTheme.teal : LensTheme.slate) }
                .padding(16).frame(maxWidth: .infinity, minHeight: 54).background(selected ? LensTheme.accentWash : LensTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(LensCardButtonStyle()).foregroundStyle(LensTheme.navy).accessibilityLabel(title).accessibilityAddTraits(selected ? .isSelected : [])
    }
}

func subjectSymbol(_ subject: CourseSubject) -> String {
    switch subject {
    case .history: "globe.americas"; case .mathematics: "function"; case .biology: "leaf"
    case .chemistry: "flask"; case .physics: "atom"; case .english: "text.book.closed"
    case .socialScience: "person.3"; case .computerScience: "chevron.left.forwardslash.chevron.right"; case .finance: "chart.line.uptrend.xyaxis"
    }
}

struct SetupLensPreview: View {
    let draft: StudentSetupDraft
    var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        ZStack {
            LensCoreView(progress: draft.completion, active: false, controls: false, contextLabel: "Study setup").frame(width: compact ? 80 : 165, height: compact ? 80 : 160)
            if !compact && !typeSize.isAccessibilitySize {
                VStack(spacing: 80) {
                    HStack { token("graduationcap", draft.year ?? "Your year"); Spacer(minLength: 8); token("books.vertical", "\(draft.subjects.count) subjects") }
                    HStack { token("timer", "\(draft.dailyMinutes) min"); Spacer(minLength: 8); token("waveform", draft.sound.title) }
                }.font(LensFont.caption2.weight(.semibold))
            }
        }.frame(maxWidth: .infinity).animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.84), value: draft.completion)
            .accessibilityElement(children: .ignore).accessibilityLabel("Study lens configured for \(draft.subjects.count) subjects and \(draft.dailyMinutes) minutes a day")
            .accessibilityValue("\(Int(draft.completion * 100)) percent complete\(reduceMotion ? ", motion off" : "")").accessibilityIdentifier("setup-lens")
    }
    private func token(_ icon: String, _ title: String) -> some View { Label(title, systemImage: icon).foregroundStyle(LensTheme.teal).padding(7).background(LensTheme.accentWash, in: Capsule()) }
}
