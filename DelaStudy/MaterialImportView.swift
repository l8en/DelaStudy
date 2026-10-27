import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import PDFKit
import Vision
import ImageIO

extension AppModel {
    var studyMaterials: [StudyMaterial] { (snapshot.workspace.materials ?? []).sorted { $0.updatedAt > $1.updatedAt } }
    @discardableResult func saveMaterial(_ material: StudyMaterial) -> Bool {
        if let error = material.validationError { presentedError = error; return false }
        let exists = studyMaterials.contains { $0.id == material.id }
        guard exists || studyMaterials.count < 60 else { presentedError = "Your desk holds 60 materials. Remove an old material before adding another."; return false }
        var copy = material; copy.updatedAt = .now
        return updateWorkspace { workspace in
            var materials = workspace.materials ?? []
            if let index = materials.firstIndex(where: { $0.id == copy.id }) { materials[index] = copy }
            else { materials.append(copy) }
            workspace.materials = materials
        }
    }
}

enum MaterialIntake: String, Identifiable {
    case file, paste, youtube, photo
    var id: String { rawValue }
    var title: String { switch self { case .file: "Import file"; case .paste: "Paste text"; case .youtube: "YouTube video"; case .photo: "Photo to text" } }
    var symbol: String { switch self { case .file: "doc.badge.arrow.up"; case .paste: "text.alignleft"; case .youtube: "play.rectangle"; case .photo: "text.viewfinder" } }
}

struct MaterialImportView: View {
    @Bindable var model: AppModel
    let intake: MaterialIntake
    var existing: StudyMaterial?
    @Environment(\.dismiss) private var dismiss
    @State private var draft = StudyMaterial(title: "", kind: .text)
    @State private var link = ""
    @State private var filePicker = false
    @State private var photo: PhotosPickerItem?
    @State private var processing = false
    @State private var error: String?
    @State private var extraction: Task<Void, Never>?
    @State private var accountID: UUID?
    @State private var loaded = false
    var body: some View {
        NavigationStack {
            Form {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--ui-testing"), ProcessInfo.processInfo.arguments.contains("--import-fixtures"), existing == nil, intake == .file || intake == .photo {
                    Section("Import pipeline test fixture") {
                        Button(intake == .file ? "Load test PDF" : "Recognize test photo") { importFixture() }
                    }
                }
                #endif
                if existing == nil {
                    Section {
                        if intake == .file {
                            Button { filePicker = true } label: { Label("Choose PDF or text file", systemImage: intake.symbol).frame(minHeight: 44) }
                            Text("Selectable text · up to 20 MB / 60 pages. Only extracted text is saved.").font(LensFont.caption)
                        } else if intake == .photo {
                            PhotosPicker(selection: $photo, matching: .images) { Label("Choose a page photo", systemImage: intake.symbol).frame(minHeight: 44) }
                            Text("Text recognition stays on this iPhone. Check the result before saving; the photo is not kept.").font(LensFont.caption)
                        } else if intake == .youtube {
                            videoURLField
                            Text("An inline player and your notes. No automatic transcript or generated questions.").font(LensFont.caption)
                        }
                    }
                }
                Section("Material") {
                    TextField("Title", text: $draft.title, prompt: Text("Title").foregroundStyle(LensTheme.slate)).accessibilityIdentifier("material-title")
                    if existing != nil && draft.kind == .youtube {
                        videoURLField
                    }
                    if draft.kind != .youtube {
                        TextEditor(text: $draft.text).frame(minHeight: 230).accessibilityLabel("Source text").accessibilityIdentifier("material-source-text")
                        HStack {
                            Text("\(draft.text.count.formatted()) / 60,000 characters").font(LensFont.caption.monospacedDigit())
                            Spacer()
                        }
                    }
                    if !draft.sourceName.isEmpty { Text(draft.sourceName).font(LensFont.caption).foregroundStyle(LensTheme.slate) }
                }
                if processing { Section { HStack { ProgressView(); Text("Reading your material…") } } }
                if let error { Section { Text(error).foregroundStyle(LensTheme.error).accessibilityIdentifier("import-error") } }
            }.disabled(processing).scrollDismissesKeyboard(.interactively)
                .navigationTitle(existing == nil ? intake.title : "Edit material").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { extraction?.cancel(); dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard model.identity.accountID == accountID else { return }
                            if draft.kind == .youtube { draft.youtubeID = StudyMaterial.videoID(from: link); draft.sourceName = "YouTube" }
                            if let validation = draft.validationError { error = validation; return }
                            if model.saveMaterial(draft) { dismiss() }
                        }.disabled(processing || draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("save-material")
                    }
                }
                .fileImporter(isPresented: $filePicker, allowedContentTypes: [.pdf, .plainText], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls): if let url = urls.first { importFile(url) }
                    case .failure(let failure):
                        if (failure as NSError).code != NSUserCancelledError { error = "Couldn’t open that file. Choose a downloaded PDF or plain-text document and try again." }
                    }
                }
                .onChange(of: photo) { _, item in
                    guard let item else { return }
                    processing = true; error = nil; extraction?.cancel()
                    extraction = Task {
                        do {
                            guard let data = try await item.loadTransferable(type: Data.self) else { throw ImportFailure.message("Couldn’t load this photo. Choose a downloaded image.") }
                            let text = try await Task.detached(priority: .userInitiated) { try MaterialExtractor.photoText(data) }.value
                            guard !Task.isCancelled, model.identity.accountID == accountID else { return }
                            draft.text = text; draft.sourceName = "Text recognized from your photo"
                            if draft.title.isEmpty { draft.title = "Class photo notes" }
                        } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
                        processing = false
                    }
                }
                .onAppear {
                    guard !loaded else { return }; loaded = true; accountID = model.identity.accountID
                    draft = existing ?? StudyMaterial(title: "", kind: intake == .youtube ? .youtube : intake == .file ? .pdf : intake == .photo ? .photo : .text)
                    if let id = draft.youtubeID { link = "https://www.youtube.com/watch?v=\(id)" }
                }
                .onDisappear { extraction?.cancel() }
        }.tint(LensTheme.teal)
    }
    private var videoURLField: some View {
        HStack {
            TextField("YouTube link", text: $link, prompt: Text("YouTube link").foregroundStyle(LensTheme.slate)).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.done)
                .accessibilityIdentifier("material-video-url")
                .onChange(of: link) { _, _ in error = nil }
            if !link.isEmpty {
                Button { link = ""; error = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(LensTheme.slate).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityLabel("Clear video link")
            }
        }
    }
    private func importFile(_ url: URL) {
        processing = true; error = nil; extraction?.cancel()
        extraction = Task {
            do {
                let text = try await Task.detached(priority: .userInitiated) { try MaterialExtractor.fileText(url) }.value
                guard !Task.isCancelled, model.identity.accountID == accountID else { return }
                draft.text = text; draft.sourceName = url.lastPathComponent
                draft.kind = url.pathExtension.lowercased() == "pdf" ? .pdf : .text
                if draft.title.isEmpty { draft.title = String(url.deletingPathExtension().lastPathComponent.prefix(120)) }
            } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
            processing = false
        }
    }
    #if DEBUG
    private func importFixture() {
        // Only reachable under both isolated UI-test flags. Exercises real
        // PDFKit/Vision extraction without depending on a cloud file provider.
        if intake == .file {
            do {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("Lens-import-pipeline-test.pdf")
                let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
                try renderer.writePDF(to: url) { context in
                    context.beginPage()
                    ("CELL MEMBRANES\nThe cell membrane regulates transport into and out of the cell." as NSString).draw(in: CGRect(x: 40, y: 40, width: 520, height: 300), withAttributes: [.font: UIFont.systemFont(ofSize: 20)])
                }
                importFile(url)
            } catch { self.error = "Couldn’t create the isolated test document." }
        } else {
            let data = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900)).jpegData(withCompressionQuality: 0.92) { context in
                UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1200, height: 900))
                ("CELL MEMBRANES\nThe cell membrane regulates transport.\nReview diffusion before the quiz." as NSString).draw(in: CGRect(x: 70, y: 80, width: 1050, height: 650), withAttributes: [.font: UIFont.systemFont(ofSize: 46), .foregroundColor: UIColor.black])
            }
            processing = true; error = nil; extraction?.cancel()
            extraction = Task {
                do {
                    let text = try await Task.detached(priority: .userInitiated) { try MaterialExtractor.photoText(data) }.value
                    guard !Task.isCancelled, model.identity.accountID == accountID else { return }
                    draft.text = text; draft.title = "Photo OCR test"; draft.sourceName = "Text recognized from test photo"
                } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
                processing = false
            }
        }
    }
    #endif
}

enum ImportFailure: LocalizedError { case message(String); var errorDescription: String? { switch self { case .message(let text): text } } }
enum MaterialExtractor {
    static func fileText(_ url: URL) throws -> String {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 20_000_000 else { throw ImportFailure.message("Use a file smaller than 20 MB.") }
        let text: String
        if url.pathExtension.lowercased() == "pdf" {
            guard let document = PDFDocument(url: url), !document.isLocked else { throw ImportFailure.message("This PDF is locked or unreadable. Choose an unlocked copy.") }
            guard document.pageCount <= 60 else { throw ImportFailure.message("Split this PDF into sections of 60 pages or fewer.") }
            text = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }.joined(separator: "\n\n")
        } else {
            let data = try Data(contentsOf: url)
            guard let decoded = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else { throw ImportFailure.message("Save this document as UTF-8 plain text and try again.") }
            text = decoded
        }
        return try checked(text)
    }
    static func photoText(_ data: Data) throws -> String {
        guard data.count <= 30_000_000, let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 2400, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else {
            throw ImportFailure.message("Choose a readable photo smaller than 30 MB.")
        }
        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate; request.usesLanguageCorrection = true; request.automaticallyDetectsLanguage = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        return try checked((request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n"))
    }
    private static func checked(_ text: String) throws -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw ImportFailure.message("No readable text found. Try a sharper page photo, or paste the text yourself.") }
        guard clean.count <= 60_000 else { throw ImportFailure.message("This has more than 60,000 characters. Import a smaller section; nothing has been cut off.") }
        return clean
    }
}

struct MaterialsView: View {
    @Bindable var model: AppModel
    @State private var intake: MaterialIntake?
    @State private var query = ""
    var body: some View {
        BearingPage(title: "My materials", eyebrow: "Your classwork") {
            MaterialIntakeGrid { intake = $0 }
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search materials", text: $query, prompt: Text("Search materials").foregroundStyle(LensTheme.slate)).autocorrectionDisabled().accessibilityIdentifier("material-search")
            }.padding(12).background(LensTheme.searchSurface, in: RoundedRectangle(cornerRadius: 12))
            MaterialList(model: model, query: query)
        }.sheet(item: $intake) { MaterialImportView(model: model, intake: $0) }
    }
}

struct MaterialIntakeGrid: View {
    var action: (MaterialIntake) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
            ForEach([MaterialIntake.file, .paste, .youtube, .photo]) { intake in
                Button { action(intake) } label: {
                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            Image(systemName: intake.symbol).font(LensFont.system(size: 22, weight: .medium)).foregroundStyle(LensTheme.teal)
                            Spacer(); Image(systemName: "plus").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        }
                        Text(intake.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                    }.frame(maxWidth: .infinity, minHeight: typeSize.isAccessibilitySize ? 110 : 72, alignment: .leading)
                        .padding(15).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(LensTheme.border, lineWidth: 1))
                }.buttonStyle(LensCardButtonStyle()).accessibilityIdentifier("intake-\(intake.rawValue)")
            }
        }
    }
}

struct MaterialList: View {
    @Bindable var model: AppModel
    var query = ""
    private var materials: [StudyMaterial] { model.studyMaterials.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.text.localizedCaseInsensitiveContains(query) || $0.notes.localizedCaseInsensitiveContains(query) } }
    var body: some View {
        if materials.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(query.isEmpty ? "Bring your classwork here." : "No matching materials.").font(LensFont.headline)
                if query.isEmpty { Text("Keep source text, notes, and your own recall cards together.").font(LensFont.subheadline).foregroundStyle(LensTheme.slate) }
            }.padding(.vertical, 20)
        }
        ForEach(materials) { material in
            NavigationLink { MaterialDetailView(model: model, id: material.id) } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: material.kind.symbol).font(LensFont.title3).foregroundStyle(LensTheme.teal).frame(width: 40, height: 44).background(LensTheme.accentWash, in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(material.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                        Text("\(material.kind.title) · \(material.cards.count) \(material.cards.count == 1 ? "card" : "cards")").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    Image(systemName: "arrow.up.right").font(LensFont.caption).foregroundStyle(LensTheme.slate).padding(.top, 8)
                }.padding(.vertical, 8).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("material-\(material.title)")
            Divider()
        }
    }
}

struct MaterialDetailView: View {
    @Bindable var model: AppModel
    let id: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var tab = "Source"
    @State private var editing = false
    @State private var deleting = false
    @State private var card: RecallCard?
    @State private var reviewing = false
    @State private var notes = ""
    @State private var notesLoaded = false
    @State private var videoLoading = true
    @State private var videoFailed = false
    private var material: StudyMaterial? { model.studyMaterials.first { $0.id == id } }
    var body: some View {
        Group {
            if let material {
                BearingPage(title: material.title, eyebrow: "\(material.kind.title) / private material") {
                    Picker("Material view", selection: $tab) { ForEach(["Source", "Notes", "Cards"], id: \.self) { Text($0) } }.pickerStyle(.segmented).accessibilityIdentifier("material-tabs")
                    if tab == "Source" {
                        if let videoID = material.youtubeID {
                            ZStack {
                                Color.black
                                YouTubeEmbedView(videoID: videoID, isLoading: $videoLoading, didFail: $videoFailed).id(playerID)
                            }.frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 14))
                            if videoLoading && !videoFailed { ProgressView("Loading player").font(LensFont.caption) }
                            Link("\(videoFailed ? "Player unavailable · open" : "Open") in YouTube", destination: URL(string: "https://www.youtube.com/watch?v=\(videoID)")!).frame(minHeight: 44).accessibilityIdentifier("open-material-youtube")
                            Button("Reload player") { videoLoading = true; videoFailed = false; editing = false; playerID = UUID() }.frame(minHeight: 44)
                        } else {
                            Text(material.text).font(LensFont.body).lineSpacing(6).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !material.sourceName.isEmpty { Text(material.sourceName).font(LensFont.caption).foregroundStyle(LensTheme.slate) }
                        Button("Edit source") { editing = true }.frame(minHeight: 44).accessibilityIdentifier("edit-material")
                    } else if tab == "Notes" {
                        TextEditor(text: $notes).frame(minHeight: 280).padding(10).scrollContentBackground(.hidden)
                            .background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12)).accessibilityLabel("Material notes")
                    } else {
                        HStack {
                            Text("\(material.cards.count) recall \(material.cards.count == 1 ? "card" : "cards")").font(LensFont.headline)
                            Spacer()
                            Button { card = RecallCard(question: "", answer: "") } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Add recall card")
                        }
                        if !material.cards.isEmpty { Button("Review cards") { reviewing = true }.buttonStyle(LensPrimaryButtonStyle()) }
                        if material.cards.isEmpty { Text("Write a question and an answer from your source. Review by revealing, then rating your recall.").font(LensFont.subheadline).foregroundStyle(LensTheme.slate) }
                        ForEach(material.cards) { item in
                            Button { card = item } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.question).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                                    Text("\(item.reviews) self-reviews").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }
                    NavigationLink { FocusView(model: model, initialTask: material.title) } label: { WorkspaceRow(symbol: "timer", title: "Focus on this material") }
                    Menu("Material actions") {
                        ShareLink(item: material.title + "\n\n" + (material.youtubeID.map { "https://www.youtube.com/watch?v=\($0)" } ?? material.text)) { Label("Share source text or link", systemImage: "square.and.arrow.up") }
                        Button("Delete material", role: .destructive) { deleting = true }
                    }.frame(minHeight: 44)
                }.toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if tab == "Notes" {
                            Button(notes == material.notes ? "Saved" : "Save notes") {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                var copy = material; copy.notes = notes; _ = model.saveMaterial(copy)
                            }.disabled(notes == material.notes).accessibilityIdentifier("save-material-notes")
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                    }
                }.onAppear {
                    if !notesLoaded { notes = material.notes; notesLoaded = true }
                    if model.snapshot.workspace.pauseSoundForVideo && material.kind == .youtube { model.focus.audio.pause() }
                }
                .sheet(isPresented: $editing) { MaterialImportView(model: model, intake: .paste, existing: material) }
                .sheet(item: $card) { CardEditor(model: model, materialID: id, original: $0) }
                .fullScreenCover(isPresented: $reviewing) { MaterialCardReview(model: model, materialID: id) }
                .confirmationDialog("Delete this material, its notes, and cards?", isPresented: $deleting, titleVisibility: .visible) {
                    Button("Delete material", role: .destructive) { if model.updateWorkspace({ $0.materials?.removeAll { $0.id == id } }) { dismiss() } }
                }
            } else { ContentUnavailableView("Material unavailable", systemImage: "doc") }
        }
    }
    @State private var playerID = UUID()
}

struct CardEditor: View {
    @Bindable var model: AppModel
    let materialID: UUID
    let original: RecallCard
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var answer = ""
    @State private var deleting = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") { TextField("What do you want to recall?", text: $question, prompt: Text("What do you want to recall?").foregroundStyle(LensTheme.slate), axis: .vertical).lineLimit(3...8).accessibilityIdentifier("card-question") }
                Section("Answer") { TextField("Write the answer", text: $answer, prompt: Text("Write the answer").foregroundStyle(LensTheme.slate), axis: .vertical).lineLimit(3...10).accessibilityIdentifier("card-answer") }
                if model.studyMaterials.first(where: { $0.id == materialID })?.cards.contains(where: { $0.id == original.id }) == true {
                    Button("Delete card", role: .destructive) { deleting = true }
                }
            }.navigationTitle("Recall card").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        guard var material = model.studyMaterials.first(where: { $0.id == materialID }) else { return }
                        var copy = original; copy.question = question; copy.answer = answer
                        if let index = material.cards.firstIndex(where: { $0.id == original.id }) { material.cards[index] = copy } else { material.cards.append(copy) }
                        if model.saveMaterial(material) { dismiss() }
                    }.disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("save-card") }
                }
                .onAppear { question = original.question; answer = original.answer }
                .confirmationDialog("Delete this recall card?", isPresented: $deleting, titleVisibility: .visible) {
                    Button("Delete card", role: .destructive) {
                        guard var material = model.studyMaterials.first(where: { $0.id == materialID }) else { return }
                        material.cards.removeAll { $0.id == original.id }; if model.saveMaterial(material) { dismiss() }
                    }
                }
        }
    }
}

struct MaterialCardReview: View {
    @Bindable var model: AppModel
    let materialID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var revealed = false
    @State private var recalled = 0
    private var material: StudyMaterial? { model.studyMaterials.first { $0.id == materialID } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let material, index < material.cards.count {
                        ProgressView(value: Double(index), total: Double(max(1, material.cards.count))).tint(LensTheme.teal).accessibilityLabel("Card \(index + 1) of \(material.cards.count)")
                        Text("CARD \(index + 1) / \(material.cards.count)").font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.teal)
                        Text(material.cards[index].question).font(LensFont.title2.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                        if revealed {
                            Divider()
                            Text(material.cards[index].answer).font(LensFont.body).lineSpacing(5).transition(.opacity)
                            HStack(spacing: 12) {
                                Button("Study again") { rate(false) }.buttonStyle(LensPrimaryButtonStyle())
                                Button("Recalled it") { rate(true) }.buttonStyle(LensPrimaryButtonStyle())
                            }
                        } else { Button("Reveal answer") { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { revealed = true } }.buttonStyle(LensPrimaryButtonStyle()) }
                    } else {
                        LensCoreView(progress: 1, active: false, controls: false, contextLabel: "Review round complete").frame(height: 180)
                        Text("Round complete").font(LensFont.title.weight(.bold))
                        Text("\(recalled) recalled · \(index - recalled) to study again").font(LensFont.headline)
                        Text("Self-rated recall. No assessed mastery or XP is assigned.").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        Button("Done") { dismiss() }.buttonStyle(LensPrimaryButtonStyle())
                    }
                }.padding(24)
            }.background(LensTheme.paper).foregroundStyle(LensTheme.navy).navigationTitle("Self-review").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
    private func rate(_ success: Bool) {
        guard var copy = material, index < copy.cards.count else { return }
        copy.cards[index].reviews += 1; copy.cards[index].lastRecalled = success
        guard model.saveMaterial(copy) else { return }
        if success { recalled += 1 }; index += 1; revealed = false
    }
}
