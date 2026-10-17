import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        Group {
            if let error = model.startupError {
                ContentUnavailableView {
                    Label("Progress needs attention", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try again", action: model.retryLoading).buttonStyle(.borderedProminent)
                    Button("Reset local progress", role: .destructive, action: model.resetProgress)
                }
            } else if !model.snapshot.hasCompletedOnboarding {
                OnboardingView(model: model)
            } else {
                MainTabView(model: model)
            }
        }
        .background(LensTheme.paper.ignoresSafeArea())
        .fontDesign(.rounded)
        .alert("Couldn’t update progress", isPresented: Binding(get: { model.presentedError != nil }, set: { if !$0 { model.presentedError = nil } })) {
            Button("OK", role: .cancel) { model.presentedError = nil }
        } message: { Text(model.presentedError ?? "Please try again.") }
        .fullScreenCover(isPresented: $model.isPracticePresented) {
            PracticeView(model: model)
        }
    }
}

struct MainTabView: View {
    @Bindable var model: AppModel
    var body: some View {
        TabView {
            NavigationStack { TodayView(model: model) }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { CourseCatalogView(model: model) }
                .tabItem { Label("Learn", systemImage: "books.vertical.fill") }
            NavigationStack { AwardsView(model: model) }
                .tabItem { Label("Awards", systemImage: "trophy.fill") }
            NavigationStack { ProfileView(model: model) }
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(LensTheme.navy)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(LensTheme.surface.opacity(0.96), for: .tabBar)
    }
}
