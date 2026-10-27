import SwiftUI

struct CourseCatalogView: View {
    @Bindable var model: AppModel
    @State private var query = ""
    @State private var subject: CourseSubject?
    @State private var level: CourseLevel?
    @State private var savedOnly = false
    @State private var offset: CGFloat = 0
    @State private var savedMessage = ""
    @State private var routeLoaded = false
    @FocusState private var searchFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var filtered: [Course] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return model.content.courses.filter {
            (subject == nil || $0.subject == subject) && (level == nil || $0.level == level)
            && (!savedOnly || model.snapshot.workspace.savedCourseIDs?.contains($0.id) == true)
            && (term.isEmpty || $0.title.localizedCaseInsensitiveContains(term) || $0.subject.title.localizedCaseInsensitiveContains(term))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LensScrollMarker()
                HStack(alignment: .firstTextBaseline) {
                    Text("Library").font(LensFont.system(.title, weight: .bold)).tracking(-0.7)
                    Spacer()
                    Text("\(model.content.courses.count) study paths").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                }.opacity(max(0, 1 + offset / 65)).accessibilityAddTraits(.isHeader)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(LensTheme.slate)
                    TextField("Course or subject", text: $query, prompt: Text("Course or subject").foregroundStyle(LensTheme.slate))
                        .font(LensFont.subheadline).autocorrectionDisabled()
                        .focused($searchFocused).submitLabel(.search).onSubmit { searchFocused = false }
                        .accessibilityIdentifier("course-search")
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44)
                        }.accessibilityLabel("Clear search")
                    }
                }.padding(.horizontal, 14).frame(minHeight: 48)
                    .background(LensTheme.searchSurface, in: RoundedRectangle(cornerRadius: 9))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 22) {
                        filter("All", selected: level == nil && !savedOnly) { level = nil; savedOnly = false }
                        ForEach([CourseLevel.highSchool, .apPreparation, .college], id: \.self) { item in
                            filter(item.title, selected: level == item && !savedOnly) { level = item; savedOnly = false }
                        }
                        filter("Saved", selected: savedOnly) { savedOnly.toggle() }
                    }
                }
                if let route = model.snapshot.workspace.studyRoute, route == .sat || route == .act || route == .honors {
                    DisclosureGroup(route.title) { Text(route.detail).font(LensFont.subheadline).padding(.top, 6) }.font(LensFont.subheadline).foregroundStyle(LensTheme.teal)
                }
                HStack {
                    Menu {
                        Button("All subjects") { subject = nil }
                        ForEach(CourseSubject.allCases, id: \.self) { s in Button(s.title) { subject = s } }
                    } label: {
                        HStack(spacing: 5) {
                            Text(subject?.title ?? "All subjects")
                            Image(systemName: "chevron.down").font(LensFont.system(size: 9, weight: .semibold))
                        }.font(LensFont.caption.weight(.medium)).frame(minHeight: 44)
                    }
                    Spacer()
                    Text(savedMessage.isEmpty ? "\(filtered.count) paths" : savedMessage)
                        .font(LensFont.caption).foregroundStyle(LensTheme.slate).lineLimit(1)
                        .accessibilityIdentifier("course-save-status")
                }
                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label(savedOnly ? "No saved courses" : "No matching courses", systemImage: savedOnly ? "bookmark" : "magnifyingglass")
                    } actions: {
                        Button("Show all courses") { query = ""; subject = nil; level = nil; savedOnly = false }
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 25) {
                    ForEach(filtered) { course in
                        courseTile(course)
                    }
                }
                NavigationLink { ImageCreditsView(model: model) } label: {
                    HStack {
                        Image(systemName: "photo")
                        Text("Image credits")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }.font(LensFont.caption).foregroundStyle(LensTheme.slate).frame(minHeight: 44)
                }.padding(.top, 6)
            }.padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 28)
        }.scrollDismissesKeyboard(.interactively).background(LensTheme.paper).foregroundStyle(LensTheme.navy)
            .onAppear { if !routeLoaded { routeLoaded = true; level = model.snapshot.workspace.studyRoute?.level } }
            .onChange(of: model.snapshot.workspace.studyRoute) { _, route in level = route?.level; savedOnly = false }
            .lensScrollSpace { offset = min(0, $0) }
            .morphingTopBar(title: "Library", symbol: "", collapsed: offset < -55)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        savedOnly.toggle()
                    } label: {
                        Image(systemName: savedOnly ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44)
                    }.accessibilityLabel(savedOnly ? "Show all courses" : "Show saved courses")
                }
            }
            .onChange(of: query) { _, _ in savedMessage = "" }
            .onChange(of: level) { _, _ in savedMessage = "" }
    }

    private func courseTile(_ course: Course) -> some View {
        let saved = model.snapshot.workspace.savedCourseIDs?.contains(course.id) == true
        let completed = StudyCurriculum.completedCount(in: StudyCurriculum.units(for: course.id), workspace: model.snapshot.workspace)
        return VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                CourseDetailView(model: model, course: course)
            } label: {
                VStack(alignment: .leading, spacing: 9) {
                    CourseImageView(courseID: course.id).frame(height: typeSize.isAccessibilitySize ? 170 : 115)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(course.level == .apPreparation ? "AP PREPARATION" : course.level == .college ? "COLLEGE" : "HIGH SCHOOL")
                        .font(LensFont.caption2.monospaced().weight(.medium)).tracking(0.4).foregroundStyle(LensTheme.teal)
                    Text(course.title.replacingOccurrences(of: " · AP® preparation", with: ""))
                        .font(LensFont.system(.subheadline, weight: .semibold)).foregroundStyle(LensTheme.navy)
                        .multilineTextAlignment(.leading).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                }
            }.buttonStyle(LensCardButtonStyle()).accessibilityIdentifier("course-\(course.id)")
            HStack(alignment: .center, spacing: 2) {
                Text("5 units · \(completed)/30 studied")
                    .font(LensFont.caption2).foregroundStyle(LensTheme.slate).lineLimit(2)
                Spacer(minLength: 0)
                Button {
                    model.toggleSavedCourse(course.id)
                    let isSaved = model.snapshot.workspace.savedCourseIDs?.contains(course.id) == true
                    savedMessage = isSaved == saved ? "" : isSaved ? "Course saved" : "Course removed"
                } label: {
                    Image(systemName: saved ? "bookmark.fill" : "bookmark")
                        .font(LensFont.system(size: 13, weight: .medium)).foregroundStyle(saved ? LensTheme.teal : LensTheme.slate)
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("\(saved ? "Unsave" : "Save") \(course.title)")
                    .accessibilityIdentifier("save-\(course.id)")
            }
            Rectangle().fill(LensTheme.border).frame(height: 1)
        }
    }

    private func filter(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16), action)
            savedMessage = ""
        } label: {
            VStack(spacing: 10) {
                Text(title).font(LensFont.caption.weight(selected ? .semibold : .medium))
                    .foregroundStyle(selected ? LensTheme.navy : LensTheme.slate)
                Rectangle().fill(selected ? LensTheme.teal : .clear).frame(height: 2)
            }.padding(.top, 12).frame(minHeight: 44)
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
