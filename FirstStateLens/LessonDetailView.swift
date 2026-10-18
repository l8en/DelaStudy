import SwiftUI
import WebKit

struct LessonDetailView: View {
    @Bindable var model: AppModel
    let course: Course
    let objective: LearningObjective
    let lessonNumber: Int
    @State private var videoLoading = true
    @State private var videoFailed = false

    private var color: Color { LensTheme.courseColor(course.subject) }
    private var material: LessonMaterial? { model.content.lesson(for: objective.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(course.level.title.uppercased()) · LESSON \(lessonNumber)").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
                    Text(objective.title).font(.system(.largeTitle, design: .rounded, weight: .heavy)).foregroundStyle(LensTheme.navy)
                    Text(material?.overview ?? objective.summary).font(.headline).foregroundStyle(LensTheme.navy).lineSpacing(4)
                }
                .padding(22).background(LensTheme.courseSurface(course.subject), in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                if let video = material?.video { videoSection(video) }
                if let material {
                    keyIdeas(material)
                    notes(material)
                    reading(material)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("CHECK YOUR UNDERSTANDING").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
                    Text("\(model.content.questions(for: objective.id).count) questions").font(.headline).foregroundStyle(LensTheme.navy)
                    Button("Take lesson test") { model.startSession(objectiveID: objective.id) }
                        .buttonStyle(LensPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 110)
        }
        .background(LensTheme.paper)
        .navigationTitle("Lesson \(lessonNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.selectCourse(course.id) }
    }

    private func videoSection(_ video: LessonVideo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WATCH").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
                Spacer()
                Text(video.duration).font(.caption.monospacedDigit()).foregroundStyle(LensTheme.slate)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.black)
                YouTubeEmbedView(videoID: video.youtubeID, isLoading: $videoLoading, didFail: $videoFailed)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .accessibilityIdentifier("lesson-video-player")
                if videoLoading && !videoFailed { ProgressView().tint(.white).controlSize(.large) }
                if videoFailed {
                    VStack(spacing: 10) {
                        Image(systemName: "wifi.exclamationmark").font(.title).foregroundStyle(.white)
                        Text("Video unavailable here").font(.headline).foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 220)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(LensTheme.border))
            Text(video.title).font(.headline).foregroundStyle(LensTheme.navy)
            HStack {
                Text(video.channel).font(.subheadline).foregroundStyle(LensTheme.slate)
                Spacer()
                Link("Open on YouTube", destination: video.watchURL).font(.subheadline.weight(.semibold))
            }
            Label("Streams from YouTube", systemImage: "wifi").font(.caption.weight(.semibold)).foregroundStyle(LensTheme.navy)
        }
    }

    private func keyIdeas(_ material: LessonMaterial) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KEY IDEAS").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
            ForEach(Array(material.keyIdeas.enumerated()), id: \.offset) { index, idea in
                HStack(alignment: .top, spacing: 13) {
                    Text("\(index + 1)").font(.caption.monospacedDigit().bold()).foregroundStyle(LensTheme.onInk)
                        .frame(width: 28, height: 28).background(color, in: Circle())
                    Text(idea).foregroundStyle(LensTheme.navy).lineSpacing(3)
                }
            }
        }
    }

    private func notes(_ material: LessonMaterial) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NOTES").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
            ForEach(material.notes, id: \.title) { section in
                VStack(alignment: .leading, spacing: 7) {
                    Text(section.title).font(.headline).foregroundStyle(LensTheme.navy)
                    Text(section.body).foregroundStyle(LensTheme.navy).lineSpacing(4)
                }
                .padding(.leading, 16).overlay(alignment: .leading) { Rectangle().fill(color).frame(width: 3) }
            }
        }
    }

    private func reading(_ material: LessonMaterial) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("READING & ATTRIBUTION").font(.caption.bold()).tracking(1.2).foregroundStyle(color)
            Link(destination: material.readingURL) { Label("Open the original reading", systemImage: "book.pages") }
                .font(.headline)
            Text(material.attribution).font(.caption).foregroundStyle(LensTheme.navy).lineSpacing(3)
        }
        .padding(18).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(LensTheme.border))
    }
}

private struct YouTubeEmbedView: UIViewRepresentable {
    let videoID: String
    @Binding var isLoading: Bool
    @Binding var didFail: Bool

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        load(videoID, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedVideoID != videoID else { return }
        context.coordinator.loadedVideoID = videoID
        isLoading = true
        didFail = false
        load(videoID, in: webView)
    }

    private func load(_ id: String, in webView: WKWebView) {
        let html = """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <style>html,body{margin:0;height:100%;background:#000;overflow:hidden}iframe{width:100%;height:100%;border:0}</style>
        </head><body>
        <iframe src="https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&rel=0&cc_load_policy=1&origin=https%3A%2F%2Fwww.youtube-nocookie.com" title="YouTube video player" allow="accelerometer; encrypted-media; picture-in-picture" allowfullscreen></iframe>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubeEmbedView
        var loadedVideoID: String
        init(parent: YouTubeEmbedView) { self.parent = parent; loadedVideoID = parent.videoID }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.isLoading = false }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { parent.isLoading = false; parent.didFail = true }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { parent.isLoading = false; parent.didFail = true }
    }
}
