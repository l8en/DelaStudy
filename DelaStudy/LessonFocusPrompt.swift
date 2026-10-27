import SwiftUI

/// A non-blocking in-app notice. It never requests system notification permission
/// or replaces another session, and it leaves the student in their lesson.
struct LessonFocusEntry: ViewModifier {
    @Bindable var model: AppModel
    let entry: LessonEntry
    let courseID: String
    let title: String
    var objectiveID: String? = nil
    var allowSound = true
    var didAdvance = false
    @State private var entered = false
    @State private var offering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if offering {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "timer").foregroundStyle(LensTheme.teal)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Focus for this lesson?").font(LensFont.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
                            Text("\(model.snapshot.workspace.focusPreferences.workMinutes) min · \(allowSound ? model.snapshot.workspace.sound.title : "Sound off for video")").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        }
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 10) {
                        Button("Enable") {
                            model.focus.start(task: title, objectiveID: objectiveID, playSound: allowSound)
                            if model.snapshot.workspace.focus != nil { offering = false }
                        }.buttonStyle(LensPrimaryButtonStyle()).accessibilityIdentifier("enable-lesson-focus")
                        Button { offering = false } label: {
                            Text("Disable").font(LensFont.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
                                .background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(LensCardButtonStyle()).accessibilityIdentifier("disable-lesson-focus")
                    }
                }.padding(12).foregroundStyle(LensTheme.navy).background(LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 16).padding(.vertical, 8).background(LensTheme.paper)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -8)))
            }
        }
        .onAppear {
            guard !entered else { return }; entered = true
            offering = model.enterLesson(entry, courseID: courseID)
        }
        .onChange(of: model.snapshot.workspace.focus?.id) { _, id in if id != nil { offering = false } }
        .onChange(of: model.snapshot.workspace.offerFocusForLessons) { _, value in if value == false { offering = false } }
        .onChange(of: didAdvance) { _, advanced in if advanced { offering = false } }
        .onChange(of: model.isPracticePresented) { _, practicing in if practicing { offering = false } }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: offering)
    }
}
