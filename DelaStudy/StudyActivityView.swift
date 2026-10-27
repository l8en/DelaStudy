import SwiftUI
import WebKit
import SafariServices

struct StudyRoute: Hashable {
    let course: Course
    let activity: StudyActivity
}

struct UnitStudyOutline: View {
    @Bindable var model: AppModel
    let course: Course
    @State private var expanded: Set<String> = []
    private var units: [StudyUnit] { StudyCurriculum.units(for: course.id) }
    var body: some View {
        let count = StudyCurriculum.completedCount(in: units, workspace: model.snapshot.workspace)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionRule(title: "Course outline")
                Text("\(count) / \(units.flatMap(\.activities).count)").font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.teal)
            }
            Text("\(units.count) units · 15 short lessons · 15 practice rounds").font(LensFont.subheadline)
            ProgressView(value: Double(count), total: Double(max(1, units.flatMap(\.activities).count))).tint(LensTheme.teal)
            ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                DisclosureGroup(isExpanded: Binding(get: { expanded.contains(unit.id) }, set: { value in
                    if value { expanded.insert(unit.id) } else { expanded.remove(unit.id) }
                })) {
                    ForEach(unit.activities) { activity in
                        NavigationLink {
                            StudyActivityView(model: model, course: course, activity: activity)
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: model.snapshot.workspace.completedActivityIDs?.contains(activity.id) == true ? "checkmark.circle.fill" : activity.kind == .reading ? "text.book.closed" : "pencil.and.outline")
                                    .foregroundStyle(LensTheme.teal).frame(width: 24)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(activity.title).font(LensFont.subheadline.weight(.medium)).foregroundStyle(LensTheme.navy)
                                    Text(activity.kind == .reading ? "Learn · 3 short steps" : "Practice · 3 questions")
                                        .font(LensFont.caption).foregroundStyle(LensTheme.slate)
                                }
                                Spacer(minLength: 0)
                            }.frame(minHeight: 52).padding(.vertical, 5)
                        }.buttonStyle(.plain).accessibilityIdentifier(activity.id)
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(unit.title).font(LensFont.headline).foregroundStyle(LensTheme.navy)
                            Text("\(StudyCurriculum.completedCount(in: [unit], workspace: model.snapshot.workspace)) / 6 studied").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        }
                    }.frame(minHeight: 58)
                }.tint(LensTheme.teal)
                Divider()
            }
        }
    }
}

struct StudyActivityView: View {
    @Bindable var model: AppModel
    let course: Course
    let activity: StudyActivity
    @State private var recalling = false
    private var isRecall: Bool { activity.kind == .recall || recalling }
    private var currentID: String { recalling ? activity.recallActivity.id : activity.id }
    var body: some View {
        Group {
            if let reading = activity.reading {
                VStack(spacing: 0) {
                    if isRecall {
                        ReadingCheckView(model: model, reading: reading, activityID: currentID).id(currentID)
                    } else {
                        BiteLessonView(model: model, reading: reading, activityID: currentID) {
                            let id = currentID
                            let saved = model.updateWorkspace { w in
                                w.completedActivityIDs = (w.completedActivityIDs ?? []).union([id])
                                w.awardedActivityIDs = (w.awardedActivityIDs ?? []).union([id])
                                w.lastActivityID = id
                                w.lastOpenedActivityID = activity.recallActivity.id
                            }
                            if saved { recalling = true }
                        }
                    }
                }
            } else {
                ContentUnavailableView("Reading unavailable", systemImage: "book.closed", description: Text("Return to the course and try again. Your saved work is unchanged."))
            }
        }.background(LensTheme.paper)
            .navigationTitle(isRecall ? "Practice" : "Learn").navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { FocusView(model: model, initialTask: activity.title) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "timer")
                            if let session = model.snapshot.workspace.focus { Text(session.isRunning ? "On" : "Paused").font(LensFont.caption.weight(.semibold)) }
                        }.frame(minWidth: 44, minHeight: 44)
                    }.accessibilityLabel("Focus on this reading")
                        .accessibilityValue(model.snapshot.workspace.focus == nil ? "Off" : model.snapshot.workspace.focus?.isRunning == true ? "Running" : "Paused")
                }
            }
            .modifier(LessonFocusEntry(model: model, entry: .activity(activity), courseID: course.id, title: activity.title, didAdvance: recalling))
    }
}

struct WebDestination: Identifiable { let id = UUID(); let url: URL }
struct BrowserSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
struct OfflineStudyReader: UIViewRepresentable {
    let model: AppModel
    let reading: StudyReading
    @Binding var source: WebDestination?
    func makeCoordinator() -> Coordinator { Coordinator(model: model, readingID: reading.id, source: $source) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false; web.backgroundColor = .clear
        web.navigationDelegate = context.coordinator
        web.scrollView.delegate = context.coordinator
        if let directory = StudyCurriculum.directory {
            let url = directory.appendingPathComponent(reading.filename)
            if FileManager.default.fileExists(atPath: url.path) { web.loadFileURL(url, allowingReadAccessTo: directory) }
            else { web.loadHTMLString(Self.unavailable, baseURL: directory) }
        }
        else { web.loadHTMLString(Self.unavailable, baseURL: nil) }
        return web
    }
    func updateUIView(_ web: WKWebView, context: Context) {}
    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) { coordinator.persist() }
    private static let unavailable = "<html><meta name='viewport' content='width=device-width,initial-scale=1'><body style='font:-apple-system-body;padding:20px'><h2>Reading couldn’t load</h2><p>Return to the course and try again, or use Source to open the original. Your saved work is unchanged.</p></body></html>"
    @MainActor class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        let model: AppModel
        let readingID: String
        let accountID: UUID?
        var restored = false
        var failed = false
        var lastFraction: Double?
        private var restoration: Task<Void, Never>?
        var source: Binding<WebDestination?>
        init(model: AppModel, readingID: String, source: Binding<WebDestination?>) { self.model = model; self.readingID = readingID; self.source = source; accountID = model.identity.accountID }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !failed else { return }
            guard !restored else { return }
            let fraction = min(1, max(0, model.snapshot.workspace.readingPositions?[readingID] ?? 0))
            restoration?.cancel()
            restoration = Task { @MainActor [weak self, weak webView] in
                // Navigation finishing precedes WebKit's asynchronous first layout.
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, let self, let webView else { return }
                webView.layoutIfNeeded()
                let height = max(0, webView.scrollView.contentSize.height-webView.scrollView.bounds.height)
                webView.scrollView.setContentOffset(CGPoint(x: 0, y: height*fraction), animated: false)
                self.restored = true
            }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { showFailure(webView) }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { showFailure(webView) }
        private func showFailure(_ web: WKWebView) {
            guard !failed else { return }
            failed = true
            web.loadHTMLString(OfflineStudyReader.unavailable, baseURL: StudyCurriculum.directory)
        }
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard restored, scrollView.window != nil, scrollView.isDragging || scrollView.isDecelerating else { return }
            let height = max(0, scrollView.contentSize.height-scrollView.bounds.height)
            lastFraction = height > 0 ? min(1, max(0, scrollView.contentOffset.y/height)) : 0
        }
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { restoration?.cancel(); restored = true }
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { persist() }
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { if !decelerate { persist() } }
        func persist() {
            guard restored, let fraction = lastFraction else { return }
            guard abs(fraction-(model.snapshot.workspace.readingPositions?[readingID] ?? 0)) > 0.002 else { return }
            let id = readingID
            Task { @MainActor in
                guard model.identity.unlocked, model.identity.accountID == accountID else { return }
                model.updateWorkspace { w in w.readingPositions = (w.readingPositions ?? [:]).merging([id: fraction]) { _, new in new } }
            }
        }
        @MainActor func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if navigationAction.navigationType == .linkActivated && ["http", "https"].contains(url.scheme ?? "") {
                source.wrappedValue = WebDestination(url: url); decisionHandler(.cancel)
            } else { decisionHandler(url.isFileURL || url.absoluteString == "about:blank" ? .allow : .cancel) }
        }
    }
}

struct LevelArrival: View {
    let level: Int
    let dismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    var body: some View {
        HStack(spacing: 14) {
            Text("\(level)").font(LensFont.title.monospacedDigit().weight(.medium)).frame(width: 52, height: 52)
                .overlay(Circle().stroke(LensTheme.onInk.opacity(0.5), lineWidth: 2))
            VStack(alignment: .leading, spacing: 4) {
                Text("LEVEL UP").font(LensFont.caption.weight(.semibold))
                Text("Level \(level) reached").font(LensFont.headline)
            }
            Spacer()
            Button(action: dismiss) { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Dismiss level up")
        }.padding(12).foregroundStyle(LensTheme.onInk).background(LensTheme.navy, in: RoundedRectangle(cornerRadius: 16))
            .offset(y: shown || reduceMotion ? 0 : -24).opacity(shown ? 1 : 0)
            .onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85)) { shown = true } }
            .accessibilityElement(children: .contain).accessibilityIdentifier("level-up-arrival")
    }
}
