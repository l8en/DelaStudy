import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var studySetup = false
    var body: some View {
        List {
            Section {
                NavigationLink { AccountSettingsView(model: model) } label: { Label("Account", systemImage: "person.crop.circle") }
                Button { studySetup = true } label: { Label("Study preferences", systemImage: "slider.horizontal.3") }.accessibilityIdentifier("edit-study-preferences")
                NavigationLink { FocusDefaultsView(model: model) } label: { Label("Focus & Zen", systemImage: "timer") }.accessibilityIdentifier("focus-settings")
                NavigationLink { NotificationSettingsView(model: model) } label: { Label("Notifications & Lock Screen", systemImage: "bell") }.accessibilityIdentifier("notification-settings")
                NavigationLink { AppDataSettingsView(model: model) } label: { Label("About & data", systemImage: "info.circle") }
            }
            Section { Button("Sign out", action: model.signOut).accessibilityIdentifier("sign-out") }
        }.lensSettingsStyle(title: "Settings")
            .sheet(isPresented: $studySetup) { StudySetupView(model: model) }
    }
}

private struct AccountSettingsView: View {
    @Bindable var model: AppModel
    @State private var name = ""
    @State private var banner = ""
    @State private var loaded = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section { ProfilePhotoEditor(model: model) }
            Section("Profile") {
                TextField("Display name", text: $name).textContentType(.nickname).accessibilityIdentifier("settings-display-name")
                if let username = model.identity.username { LabeledContent("Username", value: "@\(username)") }
                Picker("Cover subject", selection: $banner) { ForEach(CourseSubject.allCases, id: \.self) { Text($0.title).tag($0.rawValue) } }
            }
            Section { Text("Accounts are local to this iPhone. Password recovery uses its device passcode or biometrics.").font(LensFont.footnote).foregroundStyle(LensTheme.slate) }
        }.lensSettingsStyle(title: "Account")
            .onAppear { if !loaded { name = model.snapshot.profile.displayName; banner = model.snapshot.workspace.banner; loaded = true } }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { if model.updateProfile(name: name, dailyGoalMinutes: model.snapshot.profile.dailyGoalMinutes, banner: banner) { dismiss() } }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } }
    }
}

struct FocusDefaultsView: View {
    @Bindable var model: AppModel
    private func pref<T>(_ key: WritableKeyPath<FocusPreferences, T>) -> Binding<T> {
        Binding(get: { model.snapshot.workspace.focusPreferences[keyPath: key] }, set: { value in model.updateWorkspace { $0.focusPreferences[keyPath: key] = value } })
    }
    var body: some View {
        Form {
            Section {
                Toggle("Offer Focus for new lessons", isOn: Binding(get: { model.snapshot.workspace.offerFocusForLessons ?? true }, set: { value in model.updateWorkspace { $0.offerFocusForLessons = value } })).accessibilityIdentifier("lesson-focus-prompts")
            } header: { Text("Lessons") } footer: { Text("A quick Enable or Disable choice when you open a lesson for the first time.") }
            Section("Daily goal") {
                Picker("Focus minutes", selection: Binding(get: { model.snapshot.profile.dailyGoalMinutes }, set: { value in model.updateProfile(name: model.snapshot.profile.displayName, dailyGoalMinutes: value, banner: model.snapshot.workspace.banner) })) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) minutes").tag($0) }
                }
            }
            Section {
                Stepper("Work · \(model.snapshot.workspace.focusPreferences.workMinutes) min", value: pref(\.workMinutes), in: 1...180)
                Stepper("Break · \(model.snapshot.workspace.focusPreferences.breakMinutes) min", value: pref(\.breakMinutes), in: 1...30)
                Toggle("Start break automatically", isOn: pref(\.automaticBreak))
                NavigationLink("Advanced session options") { advanced }
            } header: { Text("Session rhythm") } footer: { Text("Duration changes apply to your next session.") }
            Section("Zen") {
                Toggle("Open Zen on start", isOn: pref(\.enterZen))
                Toggle("Keep display awake in Zen", isOn: pref(\.keepAwake))
                Toggle("Show upcoming tasks", isOn: pref(\.showTasks))
            }
            Section { NavigationLink("Study sounds") { SoundLibraryView(model: model) } }
        }.lensSettingsStyle(title: "Focus & Zen")
    }
    private var advanced: some View {
        Form {
            Section("Long breaks") {
                Stepper("Long break · \(model.snapshot.workspace.focusPreferences.longBreakMinutes) min", value: pref(\.longBreakMinutes), in: 5...60, step: 5)
                Stepper("Every \(model.snapshot.workspace.focusPreferences.intervalsBeforeLongBreak) work intervals", value: pref(\.intervalsBeforeLongBreak), in: 2...8)
            }
            Section("In-app feedback") {
                Toggle("Quiet in-app prompts", isOn: pref(\.suppressInAppPrompts))
                Toggle("Completion sound", isOn: pref(\.completionSound))
                Toggle("Completion haptics", isOn: pref(\.haptics))
            }
        }.lensSettingsStyle(title: "Session options")
    }
}

struct NotificationSettingsView: View {
    @Bindable var model: AppModel
    private func pref(_ key: WritableKeyPath<FocusPreferences, Bool>) -> Binding<Bool> {
        Binding(get: { model.snapshot.workspace.focusPreferences[keyPath: key] }, set: { value in
            if model.updateWorkspace({ $0.focusPreferences[keyPath: key] = value }) { model.focus.schedule() }
        })
    }
    var body: some View {
        Form {
            Section("Session alerts") {
                Toggle("Session-end alerts", isOn: pref(\.alerts))
                Toggle("Break-end alerts", isOn: pref(\.breakAlerts))
                Button("Set up optional alerts") { Task { await model.focus.requestAlerts() } }
                Text(model.focus.alertStatus).font(LensFont.footnote).foregroundStyle(LensTheme.slate)
            }
            Section("Lock Screen") {
                Toggle("Show timer on Lock Screen", isOn: Binding(get: { model.snapshot.workspace.showLiveActivity ?? true }, set: { value in
                    if model.updateWorkspace({ $0.showLiveActivity = value }) { model.focus.schedule() }
                }))
                if !model.focus.liveActivity.status.isEmpty { Text(model.focus.liveActivity.status).font(LensFont.footnote).foregroundStyle(LensTheme.slate) }
            }
            Section("Silence other apps") {
                Text("Choose allowed people and apps in iPhone Settings → Focus. Turn on your Study Focus from Control Center; this app cannot switch it on for you.").font(LensFont.subheadline)
                Link("Apple’s Focus setup guide", destination: URL(string: "https://support.apple.com/guide/iphone/set-up-a-focus-iphd6288a67f/ios")!)
            }
        }.lensSettingsStyle(title: "Notifications")
    }
}

private struct AppDataSettingsView: View {
    @Bindable var model: AppModel
    @State private var resetting = false
    var body: some View {
        List {
            Section("DelaStudy") {
                NavigationLink("Learning summary") { LearningSummaryView(model: model) }
                NavigationLink("Sound research & sources") { SoundResearchView() }
                NavigationLink("Image credits") { ImageCreditsView(model: model) }
            }
            Section("On this iPhone") {
                Text("Profiles, study notes, materials and progress stay on this device. There is no cloud sync. Password verifiers are stored in the iPhone Keychain.").font(LensFont.subheadline)
                Button("Reset this account’s progress", role: .destructive) { resetting = true }
            }
        }.lensSettingsStyle(title: "About & data")
            .confirmationDialog("Permanently remove this account’s progress?", isPresented: $resetting, titleVisibility: .visible) {
                Button("Reset progress", role: .destructive, action: model.resetProgress)
            } message: { Text("This removes your notes, materials, photo and study record, not your account or other accounts on this iPhone.") }
    }
}

private extension View {
    func lensSettingsStyle(title: String) -> some View {
        font(LensFont.body).foregroundStyle(LensTheme.navy).tint(LensTheme.teal)
            .scrollContentBackground(.hidden).background(LensTheme.paper)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}
