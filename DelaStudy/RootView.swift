import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if let error = model.startupError {
                ContentUnavailableView {
                    Label("Progress needs attention", systemImage: "exclamationmark.triangle")
                } description: { Text(error) } actions: {
                    Button("Try again", action: model.retryLoading).buttonStyle(.borderedProminent)
                    Button("Reset local progress", role: .destructive, action: model.resetProgress)
                }
            } else if !model.snapshot.hasCompletedOnboarding || !model.identity.unlocked {
                OnboardingView(model: model)
            } else if model.requiresStudentSetup {
                StudySetupView(model: model, required: true).id(model.identity.accountID)
            } else { MainTabView(model: model).id(model.identity.accountID) }
        }.background(LensTheme.paper.ignoresSafeArea())
            .foregroundStyle(LensTheme.navy)
            .alert("Couldn’t save your change", isPresented: Binding(get: { model.presentedError != nil }, set: { if !$0 { model.presentedError = nil } })) {
                Button("OK", role: .cancel) { model.presentedError = nil }
            } message: { Text(model.presentedError ?? "Please try again.") }
            .fullScreenCover(isPresented: $model.isPracticePresented) { PracticeView(model: model) }
            .sheet(isPresented: $model.openFocus) {
                NavigationStack { FocusView(model: model).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { model.openFocus = false } } } }
            }
            .onOpenURL { url in
                if url.scheme == "firststatelens", url.host == "focus" {
                    if model.workspaceAvailable { model.openFocus = true }
                    else { model.pendingFocusAfterLogin = true }
                }
            }
            .task { if model.workspaceAvailable { model.focus.restore() }; openNotifiedSession() }
            .onChange(of: StudyNotificationRoute.shared.requestID) { _, _ in openNotifiedSession() }
            .onChange(of: model.workspaceAvailable) { _, available in
                if available {
                    model.focus.restore()
                    if model.pendingFocusAfterLogin { model.pendingFocusAfterLogin = false; model.openFocus = true }
                    openNotifiedSession()
                }
            }
            .overlay(alignment: .top) {
                if let level = model.levelUp, !model.quietFocus {
                    LevelArrival(level: level) { model.levelUp = nil }.padding(.horizontal, 20).padding(.top, 10)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if model.workspaceAvailable {
                    if phase == .active { model.focus.audio.reconcile(); model.focus.restore() }
                    else { model.persistPractice() }
                }
            }
    }
    private func openNotifiedSession() {
        let route = StudyNotificationRoute.shared
        guard route.requestID != nil, model.workspaceAvailable else { return }
        defer { route.clear() }
        // Never expose another account's session or reopen an obsolete timer.
        guard route.accountID == model.identity.accountID?.uuidString,
              route.sessionID == model.snapshot.workspace.focus?.id.uuidString else { return }
        model.focus.restore()
        model.openFocus = true
    }
}
struct MainTabView: View {
    @Bindable var model: AppModel
    var body: some View {
        TabView {
            NavigationStack { TodayView(model: model) }.tabItem { Label("Today", systemImage: "square.grid.2x2") }
            NavigationStack { CourseCatalogView(model: model) }.tabItem { Label("Library", systemImage: "books.vertical") }
            NavigationStack { PlannerView(model: model) }.tabItem { Label("Plan", systemImage: "calendar") }
            NavigationStack { ReviewHubView(model: model) }.tabItem { Label("Review", systemImage: "rectangle.stack") }
            NavigationStack { ExploreView(model: model) }.tabItem { Label("Explore", systemImage: "safari") }
        }.tint(LensTheme.teal)
    }
}
