import SwiftUI

extension AppModel {
    var reviewQuestions: [PracticeQuestion] {
        WorkspaceEngine.reviewQuestions(content: content, attempts: snapshot.attempts, saved: snapshot.workspace.savedQuestionIDs ?? [])
    }
    func toggleSavedCourse(_ id: String) {
        updateWorkspace { w in
            var ids = w.savedCourseIDs ?? []
            if !ids.insert(id).inserted { ids.remove(id) }
            w.savedCourseIDs = ids
        }
    }
    func toggleSavedQuestion(_ id: String) {
        updateWorkspace { w in
            var ids = w.savedQuestionIDs ?? []
            if !ids.insert(id).inserted { ids.remove(id) }
            w.savedQuestionIDs = ids
        }
    }
    @discardableResult func saveTask(_ task: PersonalTask) -> Bool {
        var task = task
        task.title = String(task.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(160))
        guard !task.title.isEmpty else { return false }
        return updateWorkspace { w in
            if let i = w.tasks.firstIndex(where: { $0.id == task.id }) { w.tasks[i] = task }
            else { w.tasks.append(task) }
            if w.plannerDraft?.trimmingCharacters(in: .whitespacesAndNewlines) == task.title { w.plannerDraft = "" }
        }
    }
    func toggleTask(_ id: UUID) {
        updateWorkspace { w in
            if let i = w.tasks.firstIndex(where: { $0.id == id }) { w.tasks[i].isComplete.toggle() }
        }
    }
    @discardableResult func saveNote(_ text: String, objectiveID: String) -> Bool {
        updateWorkspace { w in
            let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty { w.lessonNotes.removeValue(forKey: objectiveID) }
            else { w.lessonNotes[objectiveID] = value }
            w.noteDrafts?.removeValue(forKey: objectiveID)
        }
    }
}

struct PlannerView: View {
    @Bindable var model: AppModel
    @State private var editing: PersonalTask?
    @State private var filter = "Upcoming"
    @State private var removed: PersonalTask?
    private var tasks: [PersonalTask] { WorkspaceEngine.sortedTasks(model.snapshot.workspace.tasks).filter {
        switch filter {
        case "Inbox": !$0.isComplete && $0.dueDate == nil
        case "Done": $0.isComplete
        default: !$0.isComplete
        }
    } }
    var body: some View {
        BearingPage(title: "Plan", eyebrow: Date.now.formatted(.dateTime.weekday(.wide).month().day())) {
            HStack {
                Text("\(model.snapshot.workspace.tasks.filter { !$0.isComplete }.count) open tasks").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
                Spacer()
                Button { editing = PersonalTask(title: model.snapshot.workspace.plannerDraft ?? "") } label: {
                    Label("New task", systemImage: "plus").font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44)
                }.accessibilityIdentifier("new-task")
            }
            Picker("Task view", selection: $filter) {
                ForEach(["Upcoming", "Inbox", "Done"], id: \.self) { Text($0) }
            }.pickerStyle(.segmented)
            if tasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: filter == "Done" ? "checkmark.circle" : "calendar.badge.plus").font(LensFont.title).foregroundStyle(LensTheme.teal)
                    Text(filter == "Done" ? "No completed tasks" : "No open tasks").font(LensFont.headline)
                    if filter != "Done" {
                        Button("Add a task") { editing = PersonalTask(title: "") }.frame(minHeight: 44)
                    }
                }.padding(.vertical, 30)
            }
            ForEach(tasks) { task in
                PlannerTaskRow(model: model, task: task, edit: { editing = task })
                Divider()
            }
            if let removed {
                HStack {
                    Text("Task removed").font(LensFont.caption)
                    Spacer()
                    Button("Undo") { if model.saveTask(removed) { self.removed = nil } }.frame(minHeight: 44)
                }
            }
            NavigationLink { FocusView(model: model) } label: {
                WorkspaceRow(symbol: "timer", title: "Focus session")
            }
        }
        .sheet(item: $editing) { task in TaskEditor(model: model, original: task) { removed = $0 } }
    }
}

struct PlannerTaskRow: View {
    @Bindable var model: AppModel
    let task: PersonalTask
    var edit: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button { model.toggleTask(task.id) } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isComplete ? LensTheme.success : LensTheme.slate)
                    .font(LensFont.title3).frame(width: 44, height: 44)
            }.buttonStyle(.plain).accessibilityLabel("\(task.isComplete ? "Reopen" : "Complete") \(task.title)")
            Button(action: edit) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy).strikethrough(task.isComplete).multilineTextAlignment(.leading)
                    HStack(spacing: 7) {
                        if let date = task.dueDate { Text(date, format: .dateTime.month(.abbreviated).day()) }
                        if let minutes = task.estimatedMinutes { Text("\(minutes) min") }
                        if let id = task.courseID, let course = model.content.course(id: id) { Text(course.title).lineLimit(1) }
                    }.font(LensFont.caption).foregroundStyle(LensTheme.slate)
                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }.buttonStyle(.plain).accessibilityLabel("Edit \(task.title)")
            if !task.isComplete {
                NavigationLink { FocusView(model: model, initialTask: task.title, objectiveID: task.objectiveID) } label: {
                    Image(systemName: "play.fill").font(LensFont.caption).frame(width: 44, height: 44)
                        .background(LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 10))
                }.accessibilityLabel("Focus on \(task.title)")
            }
        }
    }
}

struct TaskEditor: View {
    @Bindable var model: AppModel
    let original: PersonalTask
    var onDelete: (PersonalTask) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @State private var task = PersonalTask(title: "")
    @State private var dated = false
    @State private var estimated = false
    @State private var deleting = false
    private var exists: Bool { model.snapshot.workspace.tasks.contains { $0.id == original.id } }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                    TextField("Task title", text: $task.title, axis: .vertical).accessibilityIdentifier("task-title")
                        .accessibilityLabel("Task title")
                        .onChange(of: task.title) { _, value in
                            if !exists { model.updateWorkspace { $0.plannerDraft = String(value.prefix(160)) } }
                        }
                    if !task.title.isEmpty {
                        Button { task.title = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(LensTheme.slate).frame(width: 44, height: 44)
                        }.buttonStyle(.plain).accessibilityLabel("Clear task title")
                    }
                    }
                    Picker("Course", selection: Binding(get: { task.courseID ?? "" }, set: { task.courseID = $0.isEmpty ? nil : $0; task.objectiveID = nil })) {
                        Text("Independent study").tag("")
                        ForEach(model.content.courses) { Text($0.title).tag($0.id) }
                    }
                    if let id = task.courseID {
                        Picker("Lesson", selection: Binding(get: { task.objectiveID ?? "" }, set: { task.objectiveID = $0.isEmpty ? nil : $0 })) {
                            Text("Any lesson").tag("")
                            ForEach(model.content.objectives(for: id)) { Text($0.title).tag($0.id) }
                        }
                    }
                }
                Section {
                    Toggle("Set a date", isOn: $dated)
                    if dated { DatePicker("Due", selection: Binding(get: { task.dueDate ?? .now }, set: { task.dueDate = $0 }), displayedComponents: .date) }
                    Toggle("Time estimate", isOn: $estimated)
                    if estimated { Stepper("\(task.estimatedMinutes ?? 25) minutes", value: Binding(get: { task.estimatedMinutes ?? 25 }, set: { task.estimatedMinutes = $0 }), in: 5...180, step: 5) }
                }
                if exists { Section { Button("Delete task", role: .destructive) { deleting = true } } }
            }
            .navigationTitle(exists ? "Edit task" : "New task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if dated { task.dueDate = task.dueDate ?? .now } else { task.dueDate = nil }
                        task.estimatedMinutes = estimated ? task.estimatedMinutes ?? 25 : nil
                        if model.saveTask(task) { dismiss() }
                    }.disabled(task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("save-task")
                }
            }
            .onAppear { task = original; dated = original.dueDate != nil; estimated = original.estimatedMinutes != nil }
            .confirmationDialog("Delete this task?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete task", role: .destructive) {
                    if model.updateWorkspace({ $0.tasks.removeAll { $0.id == task.id } }) { onDelete(task); dismiss() }
                }
            }
        }.tint(LensTheme.teal)
    }
}

struct ReviewHubView: View {
    @Bindable var model: AppModel
    @State private var section = "Review"
    @State private var query = ""
    @State private var editing: LearningObjective?
    var body: some View {
        BearingPage(title: "Review & notes", eyebrow: "") {
            Picker("Study desk", selection: $section) { Text("Review").tag("Review"); Text("Notes").tag("Notes") }.pickerStyle(.segmented)
            if section == "Review" {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(model.reviewQuestions.count)").font(LensFont.system(size: 40, weight: .bold, design: .monospaced))
                    Text(model.reviewQuestions.count == 1 ? "question to revisit" : "questions to revisit").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
                }
                if model.reviewQuestions.isEmpty {
                    WorkspaceRow(symbol: "checkmark.circle", title: "No questions to revisit", detail: "Incorrect answers and bookmarked questions appear here.")
                }
                ForEach(model.reviewQuestions) { question in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(model.content.course(containing: question.objectiveID)?.title ?? "Practice").font(LensFont.caption.weight(.semibold)).foregroundStyle(LensTheme.teal)
                            Spacer()
                            Button { model.toggleSavedQuestion(question.id) } label: {
                                Image(systemName: model.snapshot.workspace.savedQuestionIDs?.contains(question.id) == true ? "bookmark.fill" : "bookmark")
                                    .frame(width: 44, height: 44)
                            }.accessibilityLabel("Bookmark question")
                        }
                        Text(question.prompt).font(LensFont.subheadline.weight(.semibold))
                        HStack {
                            Button("Practice lesson") { model.startSession(objectiveID: question.objectiveID) }.font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44)
                            Spacer()
                            if let objective = model.content.objective(id: question.objectiveID), let course = model.content.course(containing: objective.id) {
                                NavigationLink("Explanation") { LessonDetailView(model: model, course: course, objective: objective, lessonNumber: (course.objectiveIDs.firstIndex(of: objective.id) ?? 0)+1) }.font(LensFont.subheadline).frame(minHeight: 44)
                            }
                        }
                    }.padding(.vertical, 6)
                    Divider()
                }
            } else {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search your notes", text: $query)
                }.padding(12).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                let notes = model.content.objectives.filter { objective in
                    guard let note = model.snapshot.workspace.lessonNotes[objective.id], !note.isEmpty else { return false }
                    return query.isEmpty || note.localizedCaseInsensitiveContains(query) || objective.title.localizedCaseInsensitiveContains(query)
                }
                if notes.isEmpty { Text(query.isEmpty ? "Write a note inside any lesson. Find it here." : "No matching notes.").font(LensFont.subheadline).foregroundStyle(LensTheme.slate).padding(.vertical, 24) }
                ForEach(notes) { objective in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.content.course(containing: objective.id)?.title ?? "").font(LensFont.caption).foregroundStyle(LensTheme.teal)
                        Button { editing = objective } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(objective.title).font(LensFont.headline)
                                Text(model.snapshot.workspace.lessonNotes[objective.id] ?? "").font(LensFont.subheadline).lineLimit(3)
                            }.frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
                        }.buttonStyle(.plain)
                        if let course = model.content.course(containing: objective.id) {
                            NavigationLink("Open lesson", destination: LessonDetailView(model: model, course: course, objective: objective, lessonNumber: (course.objectiveIDs.firstIndex(of: objective.id) ?? 0)+1)).font(LensFont.caption.weight(.semibold)).frame(minHeight: 44)
                        }
                        Divider()
                    }
                }
            }
        }.sheet(item: $editing) { NoteEditor(model: model, objective: $0) }
    }
}

struct NoteEditor: View {
    @Bindable var model: AppModel
    let objective: LearningObjective
    @State private var text = ""
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            TextEditor(text: $text).padding(16).scrollContentBackground(.hidden).background(LensTheme.paper)
                .accessibilityLabel("Your lesson note")
                .onChange(of: text) { _, value in model.updateWorkspace { w in
                    var drafts = w.noteDrafts ?? [:]; drafts[objective.id] = value; w.noteDrafts = drafts
                } }
                .navigationTitle(objective.title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { if model.saveNote(text, objectiveID: objective.id) { dismiss() } } }
                    ToolbarItem(placement: .bottomBar) { Button("Delete note", role: .destructive) { deleting = true } }
                }
                .onAppear { text = model.snapshot.workspace.noteDrafts?[objective.id] ?? model.snapshot.workspace.lessonNotes[objective.id] ?? "" }
                .confirmationDialog("Delete this note?", isPresented: $deleting, titleVisibility: .visible) {
                    Button("Delete note", role: .destructive) { if model.saveNote("", objectiveID: objective.id) { dismiss() } }
                }
        }
    }
}

struct ExploreView: View {
    @Bindable var model: AppModel
    var body: some View {
        BearingPage(title: "Explore", eyebrow: "") {
            SectionRule(title: "Your workspace")
            NavigationLink { ProfileView(model: model) } label: {
                WorkspaceRow(symbol: "person.crop.circle", title: "Your profile", detail: "Interests & achievements")
            }
            NavigationLink { LearningSummaryView(model: model) } label: {
                WorkspaceRow(symbol: "list.bullet.rectangle", title: "Learning summary", detail: "Review before sharing")
            }
            Divider()
            SectionRule(title: "Next steps")
            NavigationLink { CollegeHubView(model: model) } label: {
                WorkspaceRow(symbol: "building.columns", title: "College & next steps", detail: "Routes, applications & financial aid")
            }
            NavigationLink { SchoolWorkspaceView(model: model) } label: {
                WorkspaceRow(symbol: "mappin.and.ellipse", title: "My school", detail: "Delaware schools & academic goals")
            }
            Divider()
            SectionRule(title: "Study together")
            NavigationLink { CommunityView(model: model) } label: {
                WorkspaceRow(symbol: "person.2", title: "Study circle", detail: "Local activities & sharing")
            }
            Divider()
            SectionRule(title: "Study tools")
            NavigationLink { FocusView(model: model) } label: {
                WorkspaceRow(symbol: "timer", title: "Focus & Zen")
            }
            NavigationLink { SoundLibraryView(model: model) } label: {
                WorkspaceRow(symbol: "waveform", title: "Sound studio")
            }
            Divider()
            NavigationLink { SettingsView(model: model) } label: {
                WorkspaceRow(symbol: "gearshape", title: "Settings")
            }.accessibilityIdentifier("explore-settings")
            NavigationLink { ImageCreditsView(model: model) } label: {
                WorkspaceRow(symbol: "photo.on.rectangle", title: "Image credits", detail: "The people & records behind the collection")
            }.accessibilityIdentifier("image-credits")
            HStack(spacing: 9) {
                LensMark().frame(width: 21, height: 21)
                Text("First State Lens").font(LensFont.caption.weight(.medium))
            }.foregroundStyle(LensTheme.slate).padding(.top, 8)
        }
    }
}
