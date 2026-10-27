import SwiftUI
import WebKit

struct LessonDetailView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let course: Course
    let objective: LearningObjective
    let lessonNumber: Int
    @State private var writing = false
    @State private var writtenDraft = ""
    @State private var saved = false
    @State private var inspectingImage: CourseImageRecord?
    private var material: LessonMaterial? { model.content.lesson(for: objective.id) }
    var body: some View {
        ScrollViewReader { reader in
            BearingPage(title: objective.title, eyebrow: course.title) {
                Text(material?.overview ?? objective.summary).font(LensFont.body).lineSpacing(5)
                HStack(spacing: 16) {
                    Button { writing = true } label: { Label("Your note", systemImage: "square.and.pencil").font(LensFont.subheadline).frame(minHeight: 44) }
                    Spacer()
                    NavigationLink { FocusView(model: model, initialTask: objective.title, objectiveID: objective.id) } label: { Label(model.snapshot.workspace.focus == nil ? "Focus" : model.snapshot.workspace.focus?.isRunning == true ? "Focus on" : "Focus paused", systemImage: "timer").font(LensFont.subheadline).frame(minHeight: 44) }.accessibilityLabel("Focus")
                        .accessibilityValue(model.snapshot.workspace.focus == nil ? "Off" : model.snapshot.workspace.focus?.isRunning == true ? "Running" : "Paused")
                }
                if let material {
                    SectionRule(title: "The essentials")
                    ForEach(Array(material.keyIdeas.enumerated()), id: \.offset) { i, idea in
                        HStack(alignment: .top, spacing: 12) {
                            Text(String(format: "%02d", i+1)).font(LensFont.caption.monospaced()).foregroundStyle(LensTheme.teal).padding(.top, 3)
                            Text(idea).font(LensFont.subheadline).lineSpacing(4)
                        }
                    }
                    if objective.id == "algebra-equations" || objective.id == "algebra-graphs" || objective.id == "college-functions" {
                        AlgebraLab()
                    }
                    if objective.id == "read-record" { SourceReasoningLab() }
                    ForEach(material.notes, id: \.title) { note in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(note.title).font(LensFont.headline).accessibilityAddTraits(.isHeader)
                            Text(note.body).font(LensFont.body).lineSpacing(5).textSelection(.enabled)
                        }
                    }
                    if let module = APPreparation.module(for: course.id) { writtenTask(module) }
                    NavigationLink { CourseDetailView(model: model, course: course, section: .resources) } label: {
                        Label("Course resources", systemImage: "books.vertical").font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }
                    DisclosureGroup("Lesson credits") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(material.attribution).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                            if let image = CourseMedia.image(for: course.id) {
                                Button("Course image & context") { inspectingImage = image }.frame(minHeight: 44)
                            }
                        }.padding(.top, 10)
                    }.font(LensFont.subheadline)
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionRule(title: "Put it into practice")
                    Text("\(model.content.questions(for: objective.id).count) questions · feedback on every answer").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    Button("Practice this lesson") { model.startSession(objectiveID: objective.id) }.buttonStyle(LensPrimaryButtonStyle())
                }.padding(.top, 8).id("practice")
            }
            .sheet(isPresented: $writing) { NoteEditor(model: model, objective: objective) }
            .sheet(item: $inspectingImage) { ImageInspectionView(record: $0) }
            .onAppear {
                writtenDraft = model.snapshot.workspace.writtenResponses[objective.id] ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { reader.scrollTo("practice", anchor: .bottom) } } label: {
                        Image(systemName: "checkmark.rectangle").frame(width: 44, height: 44)
                    }.accessibilityLabel("Jump to practice")
                }
            }
        }
        .modifier(LessonFocusEntry(model: model, entry: .foundation(objective.id), courseID: course.id, title: objective.title, objectiveID: objective.id))
    }
    private func writtenTask(_ module: APModule) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionRule(title: "Apply & explain")
            Text(module.writtenTask).font(LensFont.subheadline).lineSpacing(4)
            TextField("Write your response", text: $writtenDraft, axis: .vertical).lineLimit(5...20)
                .accessibilityLabel("Written response")
                .padding(14).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: writtenDraft) { _, _ in saved = false }
            Button(saved ? "Response saved" : "Save response") {
                saved = model.updateWorkspace { $0.writtenResponses[objective.id] = writtenDraft }
            }.frame(minHeight: 44)
            DisclosureGroup("Self-review rubric") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Use the criteria to review your own work. No official score is assigned.").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    ForEach(Array(module.rubric.enumerated()), id: \.offset) { i, criterion in
                        let key = objective.id + "-rubric-\(i)"
                        Toggle(criterion, isOn: Binding(
                            get: { model.snapshot.workspace.rubricChecks.contains(key) },
                            set: { value in model.updateWorkspace { w in
                                if value { w.rubricChecks.insert(key) } else { w.rubricChecks.remove(key) }
                            } }
                        )).font(LensFont.subheadline)
                    }
                }.padding(.top, 12)
            }.font(LensFont.subheadline)
        }
    }
}

struct SourceReasoningLab: View {
    @State private var answer: Bool?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Source or context?", systemImage: "text.magnifyingglass").font(LensFont.subheadline.weight(.semibold))
            Text("Delaware ratified the Constitution on December 7, 1787.").font(LensFont.subheadline.weight(.medium))
            Text("Is that a fact recorded by the October 24 petition, or later historical context?").font(LensFont.subheadline)
            HStack(spacing: 10) {
                Button("In the petition") { answer = false }.buttonStyle(.bordered).frame(minHeight: 44)
                Button("Later context") { answer = true }.buttonStyle(.bordered).frame(minHeight: 44)
            }
            if let answer {
                Label(answer ? "Exactly: later context." : "Look at the dates again.", systemImage: answer ? "checkmark.circle" : "arrow.counterclockwise")
                    .font(LensFont.subheadline.weight(.semibold)).foregroundStyle(answer ? LensTheme.success : LensTheme.navy)
                Text("The petition was written before ratification. Keep what the document states separate from events you learn about afterward.")
                    .font(LensFont.caption).foregroundStyle(LensTheme.slate)
            }
        }.padding(16).background(LensTheme.courseSurface(.history), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AlgebraLab: View {
    @State private var x = 0.0
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Explore a linear function", systemImage: "slider.horizontal.3").font(LensFont.subheadline.weight(.semibold))
            Text("y = 2x + 1").font(LensFont.title3.monospaced())
            Canvas { context, size in
                func point(_ x: Double, _ y: Double) -> CGPoint {
                    .init(x: size.width*CGFloat((x+3)/6), y: size.height*CGFloat(1-(y+6)/12))
                }
                var axes = Path()
                axes.move(to: point(-3, 0)); axes.addLine(to: point(3, 0))
                axes.move(to: point(0, -6)); axes.addLine(to: point(0, 6))
                context.stroke(axes, with: .color(LensTheme.slate.opacity(0.4)), lineWidth: 1)
                var line = Path(); line.move(to: point(-3, -5)); line.addLine(to: point(2.5, 6))
                context.stroke(line, with: .color(LensTheme.teal), lineWidth: 2)
                let p = point(x, 2*x+1)
                context.fill(Path(ellipseIn: .init(x: p.x-5, y: p.y-5, width: 10, height: 10)), with: .color(LensTheme.teal))
            }.frame(height: 120).accessibilityHidden(true)
            HStack {
                Text("x = \(x, specifier: "%.1f")")
                Spacer()
                Text("y = \(2*x+1, specifier: "%.1f")")
            }.font(LensFont.subheadline.monospaced())
            Slider(value: $x, in: -2...2, step: 0.5).accessibilityLabel("Input x").accessibilityValue("\(x), output \(2*x+1)")
            Text("Each increase of 1 in x adds 2 to y. At x = 0, the line crosses y = 1.")
                .font(LensFont.caption).foregroundStyle(LensTheme.slate)
        }.padding(16).background(LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct YouTubeEmbedView: UIViewRepresentable {
    let videoID: String
    @Binding var isLoading: Bool
    @Binding var didFail: Bool

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(context.coordinator, name: "lensPlayer")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        context.coordinator.beginLoad()
        load(videoID, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        guard context.coordinator.loadedVideoID != videoID else { return }
        context.coordinator.loadedVideoID = videoID
        isLoading = true
        didFail = false
        context.coordinator.beginLoad()
        load(videoID, in: webView)
    }

    private func load(_ id: String, in webView: WKWebView) {
        guard StudyMaterial.validVideoID(id) else { return }
        // Identify the embedding app, not YouTube itself, per the embedded-player
        // client-identity requirements. No external identity/account is added.
        let origin = "https://" + (Bundle.main.bundleIdentifier ?? "com.cac2026.firststatelens").lowercased()
        let html = """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <meta name="referrer" content="strict-origin-when-cross-origin">
        <style>html,body{margin:0;height:100%;background:#000;overflow:hidden}iframe{width:100%;height:100%;border:0}</style>
        </head><body>
        <iframe id="lens-player" src="https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&rel=0&cc_load_policy=1&enablejsapi=1&origin=\(origin)" referrerpolicy="strict-origin-when-cross-origin" title="YouTube video player" allow="accelerometer; encrypted-media; picture-in-picture" allowfullscreen></iframe>
        <script>
        function onYouTubeIframeAPIReady() {
          window.lensPlayer = new YT.Player('lens-player', { events: {
            onReady: function() { window.webkit.messageHandlers.lensPlayer.postMessage('ready'); },
            onError: function() { window.webkit.messageHandlers.lensPlayer.postMessage('error'); }
          }});
        }
        </script><script src="https://www.youtube.com/iframe_api"></script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: origin))
    }
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.timeout?.cancel()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "lensPlayer")
        webView.navigationDelegate = nil
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: YouTubeEmbedView
        var loadedVideoID: String
        var timeout: Task<Void, Never>?
        init(parent: YouTubeEmbedView) { self.parent = parent; loadedVideoID = parent.videoID }
        func beginLoad() {
            timeout?.cancel()
            timeout = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(12))
                guard !Task.isCancelled, let self else { return }
                if self.parent.isLoading { self.parent.isLoading = false; self.parent.didFail = true }
            }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { timeout?.cancel(); parent.isLoading = false; parent.didFail = true }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { timeout?.cancel(); parent.isLoading = false; parent.didFail = true }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "lensPlayer", let event = message.body as? String else { return }
            timeout?.cancel()
            if event == "error" { parent.isLoading = false; parent.didFail = true }
            if event == "ready" { parent.isLoading = false }
        }
    }
}
