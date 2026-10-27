import SwiftUI
import PhotosUI
import ImageIO
import UniformTypeIdentifiers

/// Only a resized, metadata-free copy is kept. The original Photos asset is untouched.
enum AvatarFiles {
    static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(ProcessInfo.processInfo.arguments.contains("--ui-testing") ? "FirstStateLens-TestAvatars" : "FirstStateLens/Avatars", isDirectory: true)
    }
    static func url(_ filename: String?) -> URL? {
        guard let filename, filename.hasSuffix(".jpg"), UUID(uuidString: String(filename.dropLast(4))) != nil else { return nil }
        return directory.appendingPathComponent(filename)
    }
    static func image(_ filename: String?) -> UIImage? {
        guard let path = url(filename)?.path else { return nil }
        return UIImage(contentsOfFile: path)
    }
    static func save(_ data: Data) throws -> String {
        guard data.count <= 25_000_000,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 768
              ] as CFDictionary) else { throw AvatarError.invalid }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { throw AvatarError.invalid }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw AvatarError.invalid }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        try (output as Data).write(to: directory.appendingPathComponent(name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return name
    }
    static func remove(_ filename: String?) { if let url = url(filename) { try? FileManager.default.removeItem(at: url) } }
    enum AvatarError: LocalizedError {
        case invalid
        var errorDescription: String? { "Choose a photo smaller than 25 MB. This image couldn’t be opened." }
    }
}

struct LearnerAvatar: View {
    let model: AppModel
    var size: CGFloat = 88
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fraction = 0.0
    @State private var previousLevel = 0
    @State private var animationTask: Task<Void, Never>?
    private var ringWidth: CGFloat { size < 50 ? 2.5 : 5 }
    private var inset: CGFloat { size < 50 ? 8 : 16 }
    var body: some View {
        ZStack {
            Circle().stroke(LensTheme.border, lineWidth: ringWidth)
            Circle().trim(from: 0, to: fraction).stroke(LensTheme.teal, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)).rotationEffect(.degrees(-90))
            Group {
                if let image = AvatarFiles.image(model.snapshot.workspace.avatarFilename) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    LearnerPortrait()
                }
            }.frame(width: size-inset, height: size-inset).clipShape(Circle())
        }.frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Profile photo, level \(model.stats.level), \(Int(model.stats.levelProgress*100)) of 100 XP toward next level")
            .onAppear { animate() }
            .onChange(of: model.stats.xp) { _, _ in animate() }
            .onChange(of: reduceMotion) { _, _ in animate() }
            .onDisappear { animationTask?.cancel() }
    }
    private func animate() {
        animationTask?.cancel()
        let stats = model.stats
        if !reduceMotion && previousLevel > 0 && stats.level > previousLevel {
            withAnimation(.easeOut(duration: 0.25)) { fraction = 1 }
            animationTask = Task {
                do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
                var transaction = Transaction(); transaction.disablesAnimations = true
                withTransaction(transaction) { fraction = 0 }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { fraction = stats.levelProgress }
            }
        } else { withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.85)) { fraction = stats.levelProgress } }
        previousLevel = stats.level
    }
}

/// A small academic portrait drawn at any size, not a name-derived placeholder.
struct LearnerPortrait: View {
    var body: some View {
        GeometryReader { g in
            let s = g.size.width
            ZStack {
                Circle().fill(LensTheme.accentWash)
                Ellipse().fill(Color(red: 0.24, green: 0.36, blue: 0.69))
                    .frame(width: s*0.78, height: s*0.62).offset(y: s*0.41)
                RoundedRectangle(cornerRadius: s*0.08).fill(Color(red: 0.83, green: 0.54, blue: 0.34))
                    .frame(width: s*0.19, height: s*0.25).offset(y: s*0.16)
                Ellipse().fill(Color(red: 0.94, green: 0.69, blue: 0.46))
                    .frame(width: s*0.42, height: s*0.48).offset(y: -s*0.02)
                UnevenRoundedRectangle(topLeadingRadius: s*0.22, bottomLeadingRadius: s*0.04, bottomTrailingRadius: s*0.02, topTrailingRadius: s*0.18)
                    .fill(Color(red: 0.13, green: 0.17, blue: 0.24))
                    .frame(width: s*0.45, height: s*0.22).rotationEffect(.degrees(-9)).offset(y: -s*0.2)
                HStack(spacing: s*0.13) {
                    Capsule().frame(width: s*0.025, height: s*0.05)
                    Capsule().frame(width: s*0.025, height: s*0.05)
                }.foregroundStyle(Color(red: 0.13, green: 0.17, blue: 0.24)).offset(y: -s*0.005)
                Image(systemName: "book.closed.fill").font(LensFont.system(size: s*0.27, weight: .medium))
                    .foregroundStyle(Color(red: 0.85, green: 0.93, blue: 0.71)).rotationEffect(.degrees(-12)).offset(x: s*0.18, y: s*0.35)
            }
        }.clipShape(Circle()).accessibilityHidden(true)
    }
}

struct ProfilePhotoEditor: View {
    @Bindable var model: AppModel
    @State private var selection: PhotosPickerItem?
    @State private var loading = false
    @State private var error: String?
    @State private var job: Task<Void, Never>?
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        Section("Profile photo") {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 20))
            layout {
                LearnerAvatar(model: model, size: 76)
                VStack(alignment: .leading, spacing: 8) {
                    let photoLabel = loading ? "Importing…" : "Choose a photo"
                    PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .compatible) {
                        Label(photoLabel, systemImage: "photo")
                    }.disabled(loading).frame(minHeight: 44).accessibilityIdentifier("choose-profile-photo")
                    if model.snapshot.workspace.avatarFilename != nil {
                        Button("Remove photo", role: .destructive) {
                            let old = model.snapshot.workspace.avatarFilename
                            if model.updateWorkspace({ $0.avatarFilename = nil }) { AvatarFiles.remove(old) }
                        }.frame(minHeight: 44)
                    }
                }
            }
            if let error { Text(error).foregroundStyle(LensTheme.error) }
        }.onChange(of: selection) { _, item in
            guard let item else { return }
            job?.cancel(); loading = true; error = nil
            job = Task {
                var created: String?
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else { throw AvatarFiles.AvatarError.invalid }
                    let name = try await Task.detached(priority: .userInitiated) { try AvatarFiles.save(data) }.value
                    created = name
                    try Task.checkCancellation()
                    let old = model.snapshot.workspace.avatarFilename
                    if model.updateWorkspace({ $0.avatarFilename = name }) { AvatarFiles.remove(old) }
                    else { AvatarFiles.remove(name) }
                } catch {
                    AvatarFiles.remove(created)
                    if !Task.isCancelled { self.error = error.localizedDescription }
                }
                loading = false; selection = nil
            }
        }.onDisappear { job?.cancel() }
    }
}
