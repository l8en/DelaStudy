import SwiftUI

struct FocusView: View {
    @Bindable var model: AppModel
    var initialTask = ""
    var objectiveID: String?
    @State private var task = ""
    @State private var newTask = ""
    @State private var zen = false
    @State private var ending = false
    @State private var restarting = false
    @FocusState private var editingTask: Bool
    @State private var loadedTask = false
    @Environment(\.scenePhase) private var scenePhase
    private var controller: FocusController { model.focus }
    var body: some View {
        BearingPage(title: "Focus", eyebrow: "Study session") {
            if let session = model.snapshot.workspace.focus {
                sessionPanel(session)
            } else {
                setup
            }
            if let id = model.snapshot.workspace.focus?.objectiveID ?? objectiveID,
               let objective = model.content.objective(id: id), let course = model.content.course(containing: id) {
                NavigationLink {
                    LessonDetailView(model: model, course: course, objective: objective, lessonNumber: (course.objectiveIDs.firstIndex(of: id) ?? 0) + 1)
                } label: {
                    WorkspaceRow(symbol: "book", title: "Open linked lesson", detail: objective.title)
                }
            }
            NavigationLink { SoundLibraryView(model:model) } label: {
                HStack { Label("Study sounds",systemImage:"waveform"); Spacer(); Text(model.snapshot.workspace.sound.title).foregroundStyle(LensTheme.slate); Image(systemName:"chevron.right") }.frame(minHeight:44)
            }
            tasks
            NavigationLink { StudyResetView() } label: { WorkspaceRow(symbol: "circle.dotted", title: "One-minute reset") }
            NavigationLink("Notifications & Lock Screen") { NotificationSettingsView(model: model) }.frame(minHeight: 44)
            history
        }
        .onAppear {
            if !loadedTask { task = initialTask.isEmpty ? model.snapshot.workspace.focusTaskDraft ?? "" : initialTask; loadedTask = true }
            controller.tick()
        }
        .onDisappear {
            if model.snapshot.workspace.focusTaskDraft != task { model.updateWorkspace { $0.focusTaskDraft = String(task.prefix(120)) } }
        }
        .onChange(of:scenePhase) { _, p in if p == .active { controller.tick() } }
        .fullScreenCover(isPresented:$zen) { ZenView(model:model) }
        .confirmationDialog("End this Focus session?",isPresented:$ending,titleVisibility:.visible) {
            Button("End and save time",role:.destructive) { controller.finishEarly() }
            Button("Keep studying",role:.cancel) {}
        } message: { Text("The time you have spent is saved. Coursework progress changes only when you answer practice questions.") }
        .confirmationDialog("Restart this session?",isPresented:$restarting,titleVisibility:.visible) {
            Button("Save time & restart") { let current = model.snapshot.workspace.focus; controller.finishEarly(); if model.snapshot.workspace.focus == nil { controller.start(task:current?.task ?? task,objectiveID:current?.objectiveID) } }
            Button("Cancel",role:.cancel) {}
        } message: { Text("Your elapsed work is saved as an early finish. A new work interval starts from the current default duration.") }
    }
    private var setup: some View {
        VStack(alignment:.leading,spacing:18) {
            TextField("What will you work on?",text:$task).textFieldStyle(.roundedBorder).accessibilityLabel("Session task")
                .focused($editingTask).submitLabel(.done).onSubmit { editingTask = false }
            HStack {
                Button("25 / 5") { model.updateWorkspace { $0.focusPreferences.workMinutes = 25; $0.focusPreferences.breakMinutes = 5 } }.buttonStyle(.bordered)
                Button("50 / 10") { model.updateWorkspace { $0.focusPreferences.workMinutes = 50; $0.focusPreferences.breakMinutes = 10 } }.buttonStyle(.bordered)
            }
            Text("\(model.snapshot.workspace.sound.title) · \(model.snapshot.workspace.focusPreferences.workMinutes) minutes of work").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
            NavigationLink("Change session settings") { FocusDefaultsView(model: model) }.frame(minHeight: 44)
            Button("Start Focus") {
                controller.start(task:task,objectiveID:objectiveID)
                if model.snapshot.workspace.focus != nil && model.snapshot.workspace.focusPreferences.enterZen { zen = true }
            }.buttonStyle(LensPrimaryButtonStyle())
        }
    }
    private func sessionPanel(_ s: FocusSession) -> some View {
        VStack(alignment:.leading,spacing:16) {
            HStack { Text(s.phase == .work ? "WORK" : "BREAK").font(LensFont.caption.bold()).foregroundStyle(LensTheme.teal); Spacer(); Text("Interval \(s.cycle)").font(LensFont.caption.monospacedDigit()) }
            Text(s.task).font(LensFont.headline)
            TimelineView(.periodic(from:.now,by:1)) { _ in
                Text(timerText(s.remaining(at:controller.now))).font(LensFont.system(size:68,weight:.medium,design:.monospaced)).monospacedDigit().minimumScaleFactor(0.55).lineLimit(1)
                    .accessibilityLabel(timerAccessibility(s.remaining(at:controller.now)))
                    .frame(maxWidth:.infinity).onChange(of:Int(s.remaining(at:controller.now))) { _,_ in controller.tick() }
            }
            if let message = s.recoveryMessage { Text(message).font(LensFont.subheadline) }
            Text(s.awaitingNextPhase ? "Interval complete" : s.isRunning ? "Running" : "Paused").font(LensFont.subheadline.weight(.semibold))
            if s.awaitingNextPhase {
                Button(s.phase == .work ? "Start break" : "Start next interval") { controller.next() }.buttonStyle(LensPrimaryButtonStyle())
            } else {
                Button(s.isRunning ? "Pause" : "Resume") { controller.togglePause() }.buttonStyle(LensPrimaryButtonStyle())
            }
            HStack {
                Button("Enter Zen",systemImage:"rectangle.expand.vertical") { zen = true }.frame(minHeight:44)
                Spacer()
                if s.phase != .work { Button("Skip break") { controller.next(skipBreak:true) }.frame(minHeight:44) }
            }
            Button("End session",role:.destructive) { ending = true }.frame(minHeight:44)
            Button("Restart session") { restarting = true }.frame(minHeight:44)
        }.padding(20).background(LensTheme.surface,in:RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(LensTheme.border))
    }
    private var tasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink { PlannerView(model: model) } label: {
                WorkspaceRow(symbol: "calendar", title: "Your study plan", detail: "Create, edit & schedule tasks")
            }
            if model.snapshot.workspace.focus == nil {
                ForEach(model.snapshot.workspace.tasks.filter { !$0.isComplete }.prefix(3)) { item in
                    Button { task = item.title } label: {
                        HStack {
                            Text(item.title).font(LensFont.subheadline).multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.left").font(LensFont.caption)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    private var history: some View {
        VStack(alignment:.leading,spacing:12) {
            SectionRule(number:"02",title:"Session record")
            ForEach(model.snapshot.workspace.focusHistory.reversed().prefix(8)) { record in
                VStack(alignment:.leading,spacing:4) {
                    Text(record.task).font(LensFont.subheadline.weight(.semibold))
                    Text("\(Int(record.focusedSeconds/60)) timer minutes · \(record.pauseCount) pauses · \(record.completed ? "finished" : "ended early")").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    Text(record.endedAt,style:.date).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                }
            }
            if model.snapshot.workspace.focusHistory.isEmpty { Text("Your saved study time will appear here.").font(LensFont.subheadline).foregroundStyle(LensTheme.slate) }
        }
    }
}

func timerText(_ seconds: TimeInterval) -> String {
    let s = max(0,Int(ceil(seconds))); return String(format:"%02d:%02d",s/60,s%60)
}
func timerAccessibility(_ seconds:TimeInterval)->String {
    let s=max(0,Int(ceil(seconds)));return "\(s/60) minutes, \(s%60) seconds remaining"
}

struct ZenView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var controls = true
    @State private var options = false
    @State private var interactionID = UUID()
    private var p: FocusPreferences { model.snapshot.workspace.focusPreferences }
    private var ink: Color { p.night ? Color(red:0.67,green:0.65,blue:0.58) : p.numeralColor == "amber" ? Color(red:0.94,green:0.73,blue:0.44) : Color(red:0.94,green:0.92,blue:0.86) }
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZenEnvironment(name:p.environment)
                VStack(spacing:10) {
                    HStack(spacing:24) {
                    VStack(spacing:10) {
                    if let s = model.snapshot.workspace.focus {
                        Text(s.phase == .work ? "FOCUS  /  \(s.cycle)" : "BREAK  /  \(s.cycle)").font(LensFont.caption.monospaced().weight(.semibold)).tracking(2)
                        if p.showCurrentTask { Text(s.task).font(LensFont.headline).lineLimit(2) }
                        TimelineView(.periodic(from:.now,by:1)) { _ in
                            Text(timerText(s.remaining(at:model.focus.now)))
                                .accessibilityLabel(timerAccessibility(s.remaining(at:model.focus.now)))
                                .font(LensFont.system(size:min(geo.size.width*0.24,geo.size.height*0.36),weight:.medium,design:.monospaced))
                                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                                .onChange(of:Int(s.remaining(at:model.focus.now))) { _,_ in model.focus.tick() }
                        }
                        Text(s.awaitingNextPhase ? "Interval complete" : s.isRunning ? "Running" : "Paused").font(LensFont.subheadline)
                        ProgressView(value:1-s.remaining(at:model.focus.now)/s.duration).tint(ink).frame(maxWidth:340).accessibilityLabel("Interval progress")
                        if p.showWallClock { Text(Date.now,style:.time).font(LensFont.caption.monospacedDigit()) }
                    } else { Text("No active session").font(LensFont.title2) }
                    }.frame(maxWidth:.infinity)
                    if p.showTasks && geo.size.width > geo.size.height && !model.snapshot.workspace.tasks.filter({!$0.isComplete}).isEmpty {
                        taskList.frame(width:min(220,geo.size.width*0.28))
                    }
                    }
                    if p.showTasks && geo.size.width <= geo.size.height { taskList }
                    if controls { controlBar }
                    else { Button("Show controls") { controls = true }.font(LensFont.caption).frame(minHeight:44) }
                }.padding(24).frame(maxWidth:.infinity,maxHeight:.infinity).foregroundStyle(ink)
            }.contentShape(Rectangle()).onTapGesture { controls = true; interactionID = UUID() }
        }.background(Color.black).preferredColorScheme(.dark)
            .task(id: interactionID) {
                try? await Task.sleep(for: .seconds(5))
                if !Task.isCancelled && !options { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { controls = false } }
            }
            .onAppear { updateIdle() }.onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of:scenePhase) { _,_ in updateIdle() }
            .onChange(of:p.keepAwake) { _,_ in updateIdle() }
            .sheet(isPresented:$options) { NavigationStack { zenOptions.navigationTitle("Zen display").toolbar { Button("Done") { options = false } } } }
    }
    private var controlBar: some View {
        HStack(spacing:12) {
            ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:12) { buttons } }
            Button("Exit Zen") { dismiss() }.frame(minHeight:44)
        }.buttonStyle(.bordered).controlSize(.regular).frame(height:50)
    }
    @ViewBuilder private var buttons: some View {
        if let s = model.snapshot.workspace.focus {
            Button(s.awaitingNextPhase ? "Next phase" : s.isRunning ? "Pause" : "Resume") { if s.awaitingNextPhase { model.focus.next() } else { model.focus.togglePause() } }.frame(minHeight:44)
        }
        Button(p.showTasks ? "Hide tasks" : "Show tasks") { model.updateWorkspace { $0.focusPreferences.showTasks.toggle() } }.frame(minHeight:44)
        Button(model.focus.audio.playing == .silence ? "Play sound" : "Stop sound") {
            if model.focus.audio.playing == .silence { options = true } else { model.focus.audio.stop() }
        }.frame(minHeight:44)
        Button("Display") { options = true }.frame(minHeight:44)
    }
    private var taskList:some View {
        VStack(alignment:.leading,spacing:6) {
            ForEach(model.snapshot.workspace.tasks.filter { !$0.isComplete }.prefix(3)) { task in
                Button { model.updateWorkspace { w in if let i = w.tasks.firstIndex(where:{ $0.id == task.id }) { w.tasks[i].isComplete = true } } } label: { Label(task.title,systemImage:"circle").font(LensFont.subheadline).multilineTextAlignment(.leading) }.frame(minHeight:44)
            }
        }
    }
    private func bind<T>(_ k: WritableKeyPath<FocusPreferences,T>) -> Binding<T> { Binding(get:{ p[keyPath:k] },set:{ v in model.updateWorkspace { $0.focusPreferences[keyPath:k] = v } }) }
    private var zenOptions: some View {
        Form {
            Picker("Environment",selection:bind(\.environment)) { Text("Observatory").tag("observatory"); Text("Coastal dusk").tag("coast"); Text("Quiet architecture").tag("architecture") }
            Picker("Numerals",selection:bind(\.numeralColor)) { Text("Paper").tag("paper"); Text("Amber").tag("amber") }
            Toggle("Show current task",isOn:bind(\.showCurrentTask))
            Toggle("Show upcoming tasks",isOn:bind(\.showTasks))
            Toggle("Show wall clock",isOn:bind(\.showWallClock))
            Toggle("Night treatment",isOn:bind(\.night))
            Toggle("Keep display awake",isOn:bind(\.keepAwake))
            Text("Environments are static to keep your attention on the work.").font(LensFont.footnote)
            NavigationLink("Study sounds") { SoundLibraryView(model:model) }
        }
    }
    private func updateIdle() { UIApplication.shared.isIdleTimerDisabled = p.keepAwake && scenePhase == .active }
}

struct ZenEnvironment: View {
    let name: String
    var body: some View {
        Canvas { c,s in
            c.fill(Path(CGRect(origin:.zero,size:s)),with:.color(name == "coast" ? Color(red:0.12,green:0.16,blue:0.2) : name == "architecture" ? Color(red:0.18,green:0.15,blue:0.12) : Color(red:0.04,green:0.1,blue:0.09)))
            if name == "architecture" {
                for i in 0..<5 {
                    let x = s.width*CGFloat(i)/5
                    var p = Path(); p.move(to:.init(x:x,y:0)); p.addLine(to:.init(x:x+s.width*0.18,y:s.height)); p.addLine(to:.init(x:x+s.width*0.26,y:s.height)); p.addLine(to:.init(x:x+s.width*0.08,y:0)); p.closeSubpath()
                    c.fill(p,with:.color(.white.opacity(0.025)))
                }
            } else {
                for i in 0..<4 {
                    let y = s.height*(0.65+CGFloat(i)*0.085)
                    var p = Path(); p.move(to:.init(x:0,y:y)); p.addCurve(to:.init(x:s.width,y:y-8),control1:.init(x:s.width*0.3,y:y-24),control2:.init(x:s.width*0.7,y:y+30))
                    c.stroke(p,with:.color(.white.opacity(0.06)),lineWidth:1)
                }
                if name == "observatory" { c.stroke(Path(ellipseIn:CGRect(x:s.width*0.15,y:-s.height*0.7,width:s.width*0.7,height:s.width*0.7)),with:.color(.white.opacity(0.05)),lineWidth:1) }
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
