import SwiftUI

struct CourseResourcesView: View {
    @Bindable var model: AppModel
    let course: Course
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded: CourseResourceKind?
    @State private var source: WebDestination?
    private var items: [CourseResource] { CourseResources.items(for: course, content: model.content) }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(CourseResourceKind.allCases) { kind in
                let resources = items.filter { $0.kind == kind }
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(reduceMotion || model.quietFocus ? nil : .spring(response: 0.34, dampingFraction: 0.9)) {
                            expanded = expanded == kind ? nil : kind
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: kind.symbol).font(LensFont.title3).frame(width: 27).accessibilityHidden(true)
                            Text(kind.title).font(LensFont.headline)
                            Spacer(minLength: 8)
                            Text("\(resources.count)").font(LensFont.subheadline.monospacedDigit()).foregroundStyle(LensTheme.slate)
                            Image(systemName: "chevron.down").font(LensFont.caption.weight(.bold)).rotationEffect(.degrees(expanded == kind ? 180 : 0)).accessibilityHidden(true)
                        }.foregroundStyle(LensTheme.navy).frame(minHeight: 68).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("resources-\(kind.rawValue)")
                        .accessibilityLabel("\(kind.title), \(resources.count) resources")
                        .accessibilityValue(expanded == kind ? "Expanded" : "Collapsed")
                        .accessibilityHint("Double tap to \(expanded == kind ? "collapse" : "expand")")
                    if expanded == kind {
                        VStack(alignment: .leading, spacing: 0) {
                            if resources.isEmpty {
                                Text(kind == .videos ? "No videos linked to this course yet." : "No resources in this category yet.")
                                    .font(LensFont.subheadline).foregroundStyle(LensTheme.slate).padding(.vertical, 18)
                            }
                            ForEach(resources) { resource in
                                Group {
                                    if let video = resource.video {
                                        NavigationLink { CourseVideoView(model: model, video: video) } label: { row(resource, action: "play.fill") }
                                            .accessibilityIdentifier("resource-video-\(video.youtubeID)")
                                    } else if let readingID = resource.readingID,
                                              let reading = StudyCurriculum.readings.values.first(where: { $0.id == readingID }) {
                                        NavigationLink { FullReadingResourceView(model: model, reading: reading) } label: { row(resource, action: "arrow.right") }
                                            .accessibilityIdentifier("resource-reading-\(readingID)")
                                    } else {
                                        Button { source = WebDestination(url: resource.url) } label: { row(resource, action: "arrow.up.right") }
                                            .accessibilityIdentifier("resource-link-\(resource.url.absoluteString)")
                                    }
                                }.buttonStyle(.plain)
                                Divider()
                            }
                        }.padding(.leading, 7).padding(.bottom, 16)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -6)))
                    }
                }
                Divider()
            }
            DisclosureGroup("Course scope") {
                Text("Short lessons cover selected ideas, not a complete year-long or credit-bearing course.").font(LensFont.subheadline).padding(.vertical, 12)
                if let ap = APPreparation.module(for: course.id) {
                    Text(ap.coverage).font(LensFont.subheadline).padding(.bottom, 12)
                    Text(ap.location).font(LensFont.subheadline)
                    Text(ap.frameworkEdition).font(LensFont.caption).padding(.bottom, 12)
                }
            }.font(LensFont.subheadline).padding(.top, 24)
            NavigationLink { StandardsDetailView(course: course) } label: {
                Label("Standards & skills", systemImage: "checklist").font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 48)
            }.padding(.top, 8)
        }.sheet(item: $source) { BrowserSheet(url: $0.url) }
    }
    private func row(_ resource: CourseResource, action: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(resource.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy).fixedSize(horizontal: false, vertical: true)
                Text(resource.publisher).font(LensFont.caption).foregroundStyle(LensTheme.slate).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: action).font(LensFont.caption.weight(.semibold)).foregroundStyle(LensTheme.teal).accessibilityHidden(true)
        }.padding(.vertical, 16).padding(.trailing, 6).frame(minHeight: 64).contentShape(Rectangle())
    }
}

struct FullReadingResourceView: View {
    @Bindable var model: AppModel
    let reading: StudyReading
    @State private var source: WebDestination?
    var body: some View {
        OfflineStudyReader(model: model, reading: reading, source: $source)
            .accessibilityIdentifier("curriculum-reader")
            .background(LensTheme.paper).navigationTitle("Full reading").navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Original") { source = WebDestination(url: reading.sourceURL) }.accessibilityIdentifier("open-original-resource") } }
            .sheet(item: $source) { BrowserSheet(url: $0.url) }
    }
}

struct CourseVideoView: View {
    @Bindable var model: AppModel
    let video: LessonVideo
    @State private var loading = true
    @State private var failed = false
    @State private var reload = UUID()
    var body: some View {
        BearingPage(title: video.title, eyebrow: video.channel) {
            ZStack {
                Color.black
                YouTubeEmbedView(videoID: video.youtubeID, isLoading: $loading, didFail: $failed)
                    .id(reload).accessibilityIdentifier("lesson-video-player")
            }.frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 12))
            if loading && !failed { ProgressView("Loading video") }
            if failed {
                Text("Video couldn't load.").font(LensFont.headline)
                Button("Try again") { failed = false; loading = true; reload = UUID() }.frame(minHeight: 44)
            }
            Link("Open YouTube", destination: video.watchURL).font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44)
        }.toolbar(.hidden, for: .tabBar)
            .onAppear { if model.snapshot.workspace.pauseSoundForVideo { model.focus.audio.pause() } }
    }
}
