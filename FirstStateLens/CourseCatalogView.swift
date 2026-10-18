import SwiftUI

struct CourseCatalogView: View {
    @Bindable var model: AppModel
    @State private var query = ""
    @State private var subject: CourseSubject?
    @State private var compactHeader = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                LensScrollMarker()
                header.scrollTransition(.animated(.snappy)) { content, phase in
                    content.opacity(phase.isIdentity ? 1 : 0.22).scaleEffect(phase.isIdentity ? 1 : 0.92)
                }
                subjectFilter
                ForEach(CourseLevel.allCases, id: \.self) { level in
                    let courses = filteredCourses.filter { $0.level == level }
                    if !courses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(level.title).font(.title3.weight(.heavy)).foregroundStyle(LensTheme.navy)
                                Spacer()
                                Text("\(courses.count)").font(.caption.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
                                    .frame(minWidth: 30, minHeight: 30).background(LensTheme.surface, in: Circle())
                            }
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(courses) { course in
                                    NavigationLink(value: course) {
                                        CourseCatalogCard(course: course, completion: model.courseCompletion(course.id), isCurrent: model.selectedCourse.id == course.id)
                                    }
                                    .buttonStyle(LensCardButtonStyle())
                                }
                            }
                        }
                    }
                }
                if filteredCourses.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .frame(maxWidth: .infinity).padding(.vertical, 60)
                }
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 110)
        }
        .background(LensTheme.paper)
        .searchable(text: $query, prompt: "Course or subject")
        .navigationDestination(for: Course.self) { CourseDetailView(model: model, course: $0) }
        .navigationBarTitleDisplayMode(.inline)
        .lensScrollSpace { compactHeader = $0 < -8 }
        .morphingTopBar(title: "Courses", symbol: "books.vertical.fill", collapsed: compactHeader)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("COURSE LIBRARY").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(LensTheme.teal)
                Text("Find your next\nchallenge")
                    .font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundStyle(LensTheme.navy)
            }
            Spacer(minLength: 8)
            Text("\(model.content.courses.count)")
                .font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundStyle(LensTheme.onInk)
                .frame(width: 76, height: 76).background(LensTheme.navy, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityLabel("\(model.content.courses.count) courses")
        }
    }

    private var subjectFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", selected: subject == nil) { subject = nil }
                ForEach(CourseSubject.allCases, id: \.self) { item in
                    filterChip(item.title, selected: subject == item) { subject = item }
                }
            }.padding(.vertical, 2)
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.bold))
                .foregroundStyle(selected ? LensTheme.onInk : LensTheme.navy)
                .padding(.horizontal, 15).frame(height: 40)
                .background(selected ? LensTheme.navy : LensTheme.surface, in: Capsule())
        }.buttonStyle(.plain)
    }

    private var filteredCourses: [Course] {
        model.content.courses.filter { course in
            (subject == nil || course.subject == subject) &&
            (query.isEmpty || course.title.localizedCaseInsensitiveContains(query) || course.subject.title.localizedCaseInsensitiveContains(query))
        }
    }
}

private struct CourseCatalogCard: View {
    let course: Course
    let completion: Double
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: course.symbolName).font(.headline.weight(.bold)).foregroundStyle(LensTheme.onInk)
                    .frame(width: 42, height: 42).background(LensTheme.navy, in: Circle())
                Spacer()
                if isCurrent { Circle().fill(LensTheme.success).frame(width: 10, height: 10).accessibilityLabel("Current course") }
            }
            Text(course.title).font(.headline.weight(.heavy)).foregroundStyle(LensTheme.navy)
                .multilineTextAlignment(.leading).lineLimit(2).frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
            HStack(spacing: 5) {
                Text("\(course.objectiveIDs.count) \(course.objectiveIDs.count == 1 ? "lesson" : "lessons")")
                Spacer()
                Text("\(Int(completion * 100))%")
            }
            .font(.caption2.monospacedDigit().weight(.bold)).foregroundStyle(LensTheme.navy)
            ProgressView(value: completion).tint(LensTheme.navy)
        }
        .padding(16).frame(maxWidth: .infinity, minHeight: 174, alignment: .topLeading)
        .background(LensTheme.courseSurface(course.subject), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
    }
}
