import SwiftUI

struct CourseCatalogView: View {
    @Bindable var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                EditorialTitle(eyebrow: "Explore", title: "Pick your next course")
                ForEach(CourseLevel.allCases, id: \.self) { level in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(level.title.uppercased()).font(.caption.bold()).tracking(1.2).foregroundStyle(LensTheme.navy)
                        ForEach(model.content.courses.filter { $0.level == level }) { course in
                            NavigationLink(value: course) {
                                CourseCatalogCard(course: course, completion: model.courseCompletion(course.id), isCurrent: model.selectedCourse.id == course.id)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 30)
        }
        .background(LensTheme.paper)
        .navigationDestination(for: Course.self) { CourseDetailView(model: model, course: $0) }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CourseCatalogCard: View {
    let course: Course
    let completion: Double
    let isCurrent: Bool
    private var background: Color { LensTheme.courseSurface(course.subject) }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: course.symbolName).font(.title2.weight(.bold)).foregroundStyle(.white)
                    .frame(width: 54, height: 54).background(LensTheme.navy, in: Circle())
                Spacer()
                if isCurrent { Text("CURRENT").font(.caption2.bold()).tracking(1).padding(.horizontal, 12).padding(.vertical, 8).background(.white.opacity(0.72), in: Capsule()) }
                Image(systemName: "arrow.up.right").font(.headline).frame(width: 42, height: 42).background(.white.opacity(0.72), in: Circle())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("\(course.level.title) · \(course.subject.title)".uppercased()).font(.caption.bold()).tracking(1).foregroundStyle(LensTheme.navy)
                Text(course.title).font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(LensTheme.navy)
            }
            HStack {
                Label("\(course.objectiveIDs.count) lessons", systemImage: "books.vertical.fill")
                Spacer(); Label("\(course.estimatedMinutes) min", systemImage: "clock.fill")
                Spacer(); Text("\(Int(completion * 100))%").monospacedDigit().fontWeight(.bold)
            }.font(.caption.weight(.semibold)).foregroundStyle(LensTheme.navy)
            ProgressView(value: completion).tint(LensTheme.navy).background(.white.opacity(0.55))
        }
        .padding(20).background(background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
