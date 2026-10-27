import Foundation
import AVFoundation
import AppKit
import QuartzCore
import CoreMedia
import CoreText

// Local-only editing of real Simulator footage. Explicit manifest entries may
// update branding credits; no synthetic statistics or audio are added.
struct ShowcaseShot: Codable {
    let id: String
    let source: String?
    let sourceStart: Double
    let sourceEnd: Double
    let duration: Double
    let title: String?
    let lines: [String]?
}
struct ShowcaseCodePopup: Codable {
    let sourcePath: String
    let firstLine: Int
    let lastLine: Int
    let start: Double
    let end: Double
    let highlightLines: [Int]
}
struct ShowcaseCreditReplacement: Codable {
    let text: String
    let start: Double
    let end: Double
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
struct ShowcaseManifest: Codable {
    let appName: String?
    let source: String
    let font: String
    let shots: [ShowcaseShot]
    let presentation: String?
    let codePopups: [ShowcaseCodePopup]?
    let devicePresentation: String?
    let codeWindowPlacement: String?
    let creditReplacement: ShowcaseCreditReplacement?
    let basePresentation: String?
    let diagramPopups: [ShowcaseDiagramPopup]?
}

@main struct ShowcaseRenderer {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else { throw failure("Use inspect VIDEO, frame VIDEO SECONDS PNG, or render MANIFEST OUTPUT [portrait].") }
        if args[1] == "inspect" { try await inspect(URL(fileURLWithPath: args[2])); return }
        if args[1] == "diagram-preview" {
            guard args.count == 5, let index = Int(args[3]) else { throw failure("Use diagram-preview MANIFEST INDEX PNG.") }
            let manifest = try JSONDecoder().decode(ShowcaseManifest.self, from: Data(contentsOf: URL(fileURLWithPath: args[2])))
            guard let diagrams = manifest.diagramPopups, diagrams.indices.contains(index) else { throw failure("No diagram at index.") }
            CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: manifest.font) as CFURL, .process, nil)
            let diagram = diagrams[index]
            let root = CALayer(); root.frame = CGRect(x: 0, y: 0, width: diagram.width, height: diagram.height)
            root.isGeometryFlipped = true; root.backgroundColor = NSColor.white.cgColor
            try ShowcaseDiagrams.install(diagram, in: root, duration: 135, preview: true)
            guard let c = CGContext(data: nil, width: Int(diagram.width), height: Int(diagram.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("Cannot allocate diagram preview.") }
            c.translateBy(x: 0, y: diagram.height); c.scaleBy(x: 1, y: -1); root.render(in: c)
            guard let image = c.makeImage(), let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw failure("Cannot encode diagram preview.") }
            try png.write(to: URL(fileURLWithPath: args[4])); return
        }
        if args[1] == "held-preview" {
            guard args.count == 5, let seconds = Double(args[3]) else { throw failure("Use held-preview VIDEO SECONDS PNG.") }
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: args[2])))
            generator.appliesPreferredTrackTransform = true
            let frame = try await generator.image(at: time(seconds))
            let root = CALayer(); root.frame = ShowcaseHandheld.canvas; root.isGeometryFlipped = true
            root.backgroundColor = NSColor.white.cgColor
            let base = CALayer(); base.frame = root.bounds; base.contents = frame.image; root.addSublayer(base)
            let movie = CALayer(); movie.frame = root.bounds; movie.contents = frame.image
            try ShowcaseHandheld.install(in: root, movie: movie, screen: CGRect(x: 170, y: 72, width: 1170 * 936 / 2532, height: 936), duration: 0)
            guard let c = CGContext(data: nil, width: 1920, height: 1080, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("Cannot allocate handheld preview.") }
            c.translateBy(x: 0, y: 1080); c.scaleBy(x: 1, y: -1)
            root.render(in: c)
            guard let image = c.makeImage(), let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw failure("Cannot encode handheld preview.") }
            try png.write(to: URL(fileURLWithPath: args[4])); return
        }
        if args[1] == "code-preview" {
            guard args.count == 5, let index = Int(args[3]) else { throw failure("Use code-preview MANIFEST INDEX PNG.") }
            let manifest = try JSONDecoder().decode(ShowcaseManifest.self, from: Data(contentsOf: URL(fileURLWithPath: args[2])))
            guard let popups = manifest.codePopups, popups.indices.contains(index) else { throw failure("No popup at that index.") }
            let rendered = try codeWindow(popups[index])
            guard let png = NSBitmapImageRep(cgImage: rendered).representation(using: .png, properties: [:]) else { throw failure("Cannot encode code preview.") }
            try png.write(to: URL(fileURLWithPath: args[4])); return
        }
        if args[1] == "contact" {
            guard args.count == 5 else { throw failure("Use contact VIDEO MANIFEST PNG.") }
            let manifest = try JSONDecoder().decode(ShowcaseManifest.self, from: Data(contentsOf: URL(fileURLWithPath: args[3])))
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: args[2])))
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero; generator.requestedTimeToleranceAfter = .zero
            generator.maximumSize = CGSize(width: 480, height: 270)
            let rows = (manifest.shots.count + 3) / 4
            guard let context = CGContext(data: nil, width: 1920, height: rows * 270, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("Cannot allocate inspection sheet.") }
            var cursor = 0.0
            for (index, shot) in manifest.shots.enumerated() {
                let frame = try await generator.image(at: time(cursor + shot.duration / 2))
                context.draw(frame.image, in: CGRect(x: (index % 4) * 480, y: (rows - 1 - index / 4) * 270, width: 480, height: 270))
                cursor += shot.duration
            }
            guard let image = context.makeImage(), let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw failure("Cannot encode inspection sheet.") }
            try png.write(to: URL(fileURLWithPath: args[4])); print("Decoded every chapter midpoint."); return
        }
        if args[1] == "frame" {
            guard args.count == 5, let seconds = Double(args[3]) else { throw failure("Expected a video, seconds and PNG path.") }
            let asset = AVURLAsset(url: URL(fileURLWithPath: args[2]))
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1920, height: 1920)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            let frame = try await generator.image(at: time(seconds))
            let image = NSBitmapImageRep(cgImage: frame.image)
            guard let png = image.representation(using: .png, properties: [:]) else { throw failure("Could not encode inspection frame.") }
            try png.write(to: URL(fileURLWithPath: args[4]))
            print("Saved frame at \(CMTimeGetSeconds(frame.actualTime)) seconds."); return
        }
        guard args[1] == "render", args.count >= 4 else { throw failure("Expected render MANIFEST OUTPUT [portrait].") }
        let manifest = try JSONDecoder().decode(ShowcaseManifest.self, from: Data(contentsOf: URL(fileURLWithPath: args[2])))
        try await render(manifest, output: URL(fileURLWithPath: args[3]), portrait: args.dropFirst(4).contains("portrait"))
    }
    static func time(_ seconds: Double) -> CMTime { CMTime(seconds: seconds, preferredTimescale: 600) }
    static func failure(_ message: String) -> NSError { NSError(domain: "Showcase", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    static func color(_ value: UInt32) -> NSColor {
        NSColor(srgbRed: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1)
    }
    static func inspect(_ url: URL) async throws {
        let asset = AVURLAsset(url: url)
        let video = try await asset.loadTracks(withMediaType: .video)
        let audio = try await asset.loadTracks(withMediaType: .audio)
        let duration = try await asset.load(.duration)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        var values: [String: Any] = ["duration": CMTimeGetSeconds(duration), "videoTracks": video.count, "audioTracks": audio.count,
            "bytes": attributes[.size] ?? 0, "creationEpoch": (attributes[.creationDate] as? Date)?.timeIntervalSince1970 ?? 0]
        if let track = video.first {
            let size = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let rect = CGRect(origin: .zero, size: size).applying(transform)
            values["width"] = abs(rect.width); values["height"] = abs(rect.height)
            if let format = try await track.load(.formatDescriptions).first {
                let code = CMFormatDescriptionGetMediaSubType(format)
                values["codec"] = String(bytes: [UInt8((code >> 24) & 255), UInt8((code >> 16) & 255), UInt8((code >> 8) & 255), UInt8(code & 255)], encoding: .ascii)
            }
        }
        print(String(data: try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys, .prettyPrinted]), encoding: .utf8)!)
    }
    @MainActor static func render(_ manifest: ShowcaseManifest, output: URL, portrait: Bool) async throws {
        guard !FileManager.default.fileExists(atPath: output.path) else { throw failure("Output already exists; choose a new filename to preserve it.") }
        let preservingWalkthrough = manifest.basePresentation != nil
        guard !preservingWalkthrough || !portrait else { throw failure("A finished presentation must stay landscape.") }
        let source = AVURLAsset(url: URL(fileURLWithPath: manifest.basePresentation ?? manifest.source))
        // AVAssetTrack's owning asset must stay alive while its ranges are copied
        // and exported, including the supplementary evidence recording.
        var retainedSources = [source]
        defer { withExtendedLifetime(retainedSources) {} }
        guard let original = try await source.loadTracks(withMediaType: .video).first else { throw failure("Source has no video track.") }
        let sourceDuration = CMTimeGetSeconds(try await source.load(.duration))
        let naturalSize = try await original.load(.naturalSize)
        let preferredTransform = try await original.load(.preferredTransform)
        let bounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let sourceSize = CGSize(width: abs(bounds.width), height: abs(bounds.height))
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw failure("Cannot create composition track.") }
        var cursor = 0.0
        var starts: [(ShowcaseShot, Double)] = []
        for shot in manifest.shots {
            if preservingWalkthrough {
                guard shot.duration > 0 else { throw failure("Invalid chapter duration.") }
                starts.append((shot, cursor)); cursor += shot.duration; continue
            }
            var sourceTrack = original
            var availableDuration = sourceDuration
            if let alternate = shot.source {
                let asset = AVURLAsset(url: URL(fileURLWithPath: alternate))
                retainedSources.append(asset)
                guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw failure("Alternate source has no video.") }
                guard try await track.load(.naturalSize) == naturalSize else { throw failure("Alternate source dimensions differ.") }
                sourceTrack = track; availableDuration = CMTimeGetSeconds(try await asset.load(.duration))
            }
            guard shot.duration > 0, shot.sourceStart >= 0, shot.sourceEnd > shot.sourceStart, shot.sourceEnd <= availableDuration + 0.1 else { throw failure("Invalid source range for \(shot.id).") }
            let inserted = CMTimeRange(start: time(shot.sourceStart), duration: time(shot.sourceEnd - shot.sourceStart))
            try videoTrack.insertTimeRange(inserted, of: sourceTrack, at: time(cursor))
            let placed = CMTimeRange(start: time(cursor), duration: inserted.duration)
            videoTrack.scaleTimeRange(placed, toDuration: time(shot.duration))
            starts.append((shot, cursor)); cursor += shot.duration
        }
        if preservingWalkthrough {
            guard abs(sourceDuration - cursor) < 0.04, sourceSize == CGSize(width: 1920, height: 1080) else { throw failure("The preserved walkthrough must have identical dimensions and duration.") }
            try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: time(cursor)), of: original, at: .zero)
        }
        guard cursor < 180 else { throw failure("Showcase must be shorter than three minutes.") }
        let outputSize = portrait ? sourceSize : CGSize(width: 1920, height: 1080)
        let phoneHeight: CGFloat = 936
        let scale = portrait ? 1 : phoneHeight / sourceSize.height
        let phone = portrait ? CGRect(origin: .zero, size: sourceSize) : CGRect(x: 170, y: 72, width: preservingWalkthrough ? 1170 * 936 / 2532 : sourceSize.width * scale, height: phoneHeight)
        let normalized = preferredTransform.concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
        let transform = preservingWalkthrough ? normalized : normalized.concatenating(CGAffineTransform(scaleX: scale, y: scale)).concatenating(CGAffineTransform(translationX: phone.minX, y: phone.minY))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: time(cursor))
        let codePresentation = manifest.presentation == "code-windows"
        instruction.backgroundColor = color(codePresentation ? 0xFFFFFF : 0xF5F4EF).cgColor
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(transform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        let video = AVMutableVideoComposition()
        video.instructions = [instruction]; video.renderSize = outputSize
        video.frameDuration = CMTime(value: 1, timescale: 30)
        CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: manifest.font) as CFURL, .process, nil)
        let creditLayers = try creditReplacement(manifest.creditReplacement, screen: phone, sourceSize: sourceSize, duration: cursor)
        if portrait {
            // Keep the final static Simulator frame through the requested end.
            // The Core Animation timing path avoids a shortened VFR export;
            // this layer adds no visible title, graphic, or watermark.
            let root = CALayer(); root.frame = CGRect(origin: .zero, size: outputSize)
            let movie = CALayer(); movie.frame = root.bounds; root.addSublayer(movie)
            let credits = CALayer(); credits.frame = root.bounds; credits.isGeometryFlipped = true
            for layer in creditLayers { credits.addSublayer(layer) }
            root.addSublayer(credits)
            let clock = CABasicAnimation(keyPath: "opacity"); clock.fromValue = 1; clock.toValue = 1
            clock.duration = cursor; clock.beginTime = AVCoreAnimationBeginTimeAtZero
            clock.isRemovedOnCompletion = false; clock.fillMode = .both
            movie.add(clock, forKey: "frame-clock")
            video.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: movie, in: root)
        }
        if !portrait {
            let root = CALayer(); root.frame = CGRect(origin: .zero, size: outputSize)
            root.isGeometryFlipped = true
            root.backgroundColor = color(codePresentation ? 0xFFFFFF : 0xF5F4EF).cgColor
            let movie = CALayer(); movie.frame = root.bounds
            if preservingWalkthrough {
                // Reuse the approved, finished movie with NO retiming, reframing,
                // new footage or changes to the phone. Replace only its side panel.
                let mask = CAShapeLayer(); mask.frame = root.bounds
                mask.path = CGPath(rect: CGRect(x: 0, y: 0, width: 670, height: 1080), transform: nil)
                mask.fillColor = NSColor.black.cgColor; movie.mask = mask
                root.addSublayer(movie)
            } else if ["iphone-14-pro-held", "iphone-14-pro"].contains(manifest.devicePresentation ?? "") {
                try ShowcaseHandheld.install(in: root, movie: movie, screen: phone, duration: cursor, screenOverlays: creditLayers, includeHand: manifest.devicePresentation == "iphone-14-pro-held")
            } else {
            root.addSublayer(movie)
            let outline = CAShapeLayer()
            outline.frame = root.bounds
            outline.path = CGPath(roundedRect: phone.insetBy(dx: -3, dy: -3), cornerWidth: 28, cornerHeight: 28, transform: nil)
            outline.fillColor = NSColor.clear.cgColor; outline.strokeColor = color(0x18233A).cgColor; outline.lineWidth = 3
            root.addSublayer(outline)
            for layer in creditLayers { root.addSublayer(layer) }
            }
            if codePresentation {
                for diagram in manifest.diagramPopups ?? [] {
                    try ShowcaseDiagrams.install(diagram, in: root, duration: cursor)
                }
                for popup in manifest.codePopups ?? [] {
                    guard popup.start >= 0, popup.end > popup.start + 1, popup.end <= cursor else { throw failure("Invalid code popup timing.") }
                    let image = try codeWindow(popup)
                    let lowerRight = manifest.codeWindowPlacement == "lower-right"
                    if lowerRight && image.height > 660 { throw failure("Code excerpt is too tall to preserve the webcam area.") }
                    let windowY = lowerRight ? 1020 - CGFloat(image.height) : (1080 - CGFloat(image.height)) / 2
                    let window = CALayer()
                    window.frame = CGRect(x: 730, y: windowY, width: CGFloat(image.width), height: CGFloat(image.height))
                    window.contents = image; window.contentsGravity = .resize
                    window.cornerRadius = 16; window.opacity = 0
                    window.shadowColor = NSColor.black.cgColor; window.shadowOpacity = 0.13
                    window.shadowRadius = 28; window.shadowOffset = CGSize(width: 0, height: 14)
                    window.shadowPath = CGPath(roundedRect: window.bounds, cornerWidth: 16, cornerHeight: 16, transform: nil)
                    animatePopup(window, start: popup.start, end: popup.end, duration: cursor)
                    root.addSublayer(window)
                }
            } else {
            root.addSublayer(text(manifest.appName ?? "DelaStudy", frame: CGRect(x: 770, y: 100, width: 1020, height: 48), size: 26, color: 0x3455D1, bold: true))
            for (shot, start) in starts {
                let section = CALayer(); section.frame = root.bounds; section.opacity = 0
                section.addSublayer(text(shot.title ?? "", frame: CGRect(x: 770, y: 218, width: 990, height: 230), size: 72, color: 0x18233A, bold: true))
                for (i, line) in (shot.lines ?? []).enumerated() {
                    section.addSublayer(text(line, frame: CGRect(x: 774, y: 495 + CGFloat(i) * 92, width: 955, height: 84), size: 34, color: 0x18233A))
                }
                let points: [(Double, Float)] = [(0, 0), (start / cursor, 0), ((start + 0.12) / cursor, 1), ((start + shot.duration - 0.12) / cursor, 1), ((start + shot.duration) / cursor, 0), (1, 0)]
                var unique: [Double: Float] = [:]; for (key, value) in points { unique[key] = value }
                let sorted = unique.keys.sorted()
                let animation = CAKeyframeAnimation(keyPath: "opacity")
                animation.keyTimes = sorted.map { NSNumber(value: $0) }
                animation.values = sorted.map { NSNumber(value: unique[$0]!) }
                animation.duration = cursor; animation.beginTime = AVCoreAnimationBeginTimeAtZero
                animation.isRemovedOnCompletion = false; animation.fillMode = .both
                section.add(animation, forKey: "chapter-visibility"); root.addSublayer(section)
            }
            root.addSublayer(text("iPhone Simulator · Demonstration account", frame: CGRect(x: 774, y: 906, width: 1040, height: 42), size: 23, color: 0x546078))
            let rail = CALayer(); rail.frame = CGRect(x: 774, y: 1000, width: 1010, height: 4); rail.backgroundColor = color(0xDCE1EB).cgColor
            root.addSublayer(rail)
            let progress = CALayer(); progress.anchorPoint = CGPoint(x: 0, y: 0.5); progress.position = CGPoint(x: 774, y: 1002)
            progress.bounds = CGRect(x: 0, y: 0, width: 1010, height: 4); progress.backgroundColor = color(0x3455D1).cgColor
            let fill = CABasicAnimation(keyPath: "transform.scale.x"); fill.fromValue = 0; fill.toValue = 1
            fill.duration = cursor; fill.beginTime = AVCoreAnimationBeginTimeAtZero; fill.isRemovedOnCompletion = false; fill.fillMode = .both
            progress.add(fill, forKey: "elapsed"); root.addSublayer(progress)
            }
            video.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: movie, in: root)
        }
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { throw failure("Cannot create video exporter.") }
        exporter.videoComposition = video; exporter.shouldOptimizeForNetworkUse = true
        exporter.timeRange = CMTimeRange(start: .zero, duration: time(cursor))
        print("Exporting \(cursor) seconds to \(output.path)")
        try await exporter.export(to: output, as: .mp4)
        try await inspect(output)
    }
    @MainActor static func creditReplacement(_ replacement: ShowcaseCreditReplacement?, screen: CGRect, sourceSize: CGSize, duration: Double) throws -> [CALayer] {
        guard let replacement else { return [] }
        guard replacement.start >= 0, replacement.end > replacement.start, replacement.end <= duration else { throw failure("Invalid credit replacement timing.") }
        let width = Int(replacement.width), height = Int(replacement.height)
        guard let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("Cannot allocate credit branding image.") }
        c.setFillColor(color(0xF5F4EF).cgColor); c.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let styled = NSAttributedString(string: replacement.text, attributes: [.font: CTFontCreateWithName("Manrope-Regular" as CFString, 36, nil), .foregroundColor: color(0x546078).cgColor])
        let line = CTLineCreateWithAttributedString(styled)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        c.textPosition = CGPoint(x: 8, y: (CGFloat(height) - bounds.height) / 2 - bounds.minY)
        CTLineDraw(line, c)
        guard let image = c.makeImage() else { throw failure("Cannot create credit branding image.") }
        let layer = CALayer(); layer.contents = image
        let scale = screen.width / sourceSize.width
        layer.frame = CGRect(x: screen.minX + replacement.x * scale, y: screen.minY + replacement.y * scale, width: replacement.width * scale, height: replacement.height * scale)
        layer.opacity = 0
        let visibility = CAKeyframeAnimation(keyPath: "opacity")
        visibility.keyTimes = [0, NSNumber(value: replacement.start / duration), NSNumber(value: replacement.end / duration), 1]
        visibility.values = [0, 1, 0, 0]; visibility.calculationMode = .discrete
        visibility.duration = duration; visibility.beginTime = AVCoreAnimationBeginTimeAtZero
        visibility.isRemovedOnCompletion = false; visibility.fillMode = .both
        layer.add(visibility, forKey: "credit-branding")
        return [layer]
    }
    @MainActor static func animatePopup(_ layer: CALayer, start: Double, end: Double, duration: Double) {
        let times = [0, start / duration, (start + 0.28) / duration, (end - 0.2) / duration, end / duration, 1]
        for (key, values) in [("opacity", [0.0, 0, 1, 1, 0, 0]), ("transform.translation.y", [20.0, 20, 0, 0, -8, -8]), ("transform.scale", [0.985, 0.985, 1, 1, 0.995, 0.995])] {
            let animation = CAKeyframeAnimation(keyPath: key)
            animation.keyTimes = times.map { NSNumber(value: $0) }; animation.values = values
            animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: times.count - 1)
            animation.duration = duration; animation.beginTime = AVCoreAnimationBeginTimeAtZero
            animation.isRemovedOnCompletion = false; animation.fillMode = .both
            layer.add(animation, forKey: key)
        }
    }
    @MainActor static func codeWindow(_ popup: ShowcaseCodePopup) throws -> CGImage {
        // Read source directly, rather than composing plausible-looking example code.
        // Only shared indentation and visual line wrapping change for presentation.
        let source = try String(contentsOfFile: popup.sourcePath, encoding: .utf8).components(separatedBy: "\n")
        guard popup.firstLine > 0, popup.lastLine >= popup.firstLine, popup.lastLine <= source.count else { throw failure("Code range is outside \(popup.sourcePath).") }
        let excerpt = Array(source[(popup.firstLine - 1)...(popup.lastLine - 1)])
        let indent = excerpt.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.map { $0.prefix(while: { $0 == " " }).count }.min() ?? 0
        let fontSize: CGFloat = 24, lineHeight: CGFloat = 36
        let width = 1070, codeX: CGFloat = 86, codeWidth: CGFloat = 950
        struct Row { let text: NSAttributedString; let sourceLine: Int; let continuation: Bool }
        var rows: [Row] = []
        for (index, original) in excerpt.enumerated() {
            let line = String(original.dropFirst(min(indent, original.prefix(while: { $0 == " " }).count)))
            let styled = syntax(line, size: fontSize)
            let setter = CTTypesetterCreateWithAttributedString(styled)
            let units = Array(line.utf16)
            func identifier(_ unit: UInt16) -> Bool {
                (65...90).contains(unit) || (97...122).contains(unit) || (48...57).contains(unit) || unit == 95
            }
            var offset = 0
            if styled.length == 0 { rows.append(Row(text: styled, sourceLine: popup.firstLine + index, continuation: false)) }
            while offset < styled.length {
                var count = CTTypesetterSuggestLineBreak(setter, offset, Double(codeWidth - (offset == 0 ? 0 : 24)))
                // Visual wrapping must not split a Swift identifier (e.g. .count).
                // Keep the source intact; only choose a clearer display break.
                if offset + count < units.count, count > 0,
                   identifier(units[offset + count - 1]), identifier(units[offset + count]) {
                    var boundary = count
                    while boundary > 0 && identifier(units[offset + boundary - 1]) { boundary -= 1 }
                    if boundary > 0 && units[offset + boundary - 1] == 46 { boundary -= 1 }
                    if boundary > 0 { count = boundary }
                }
                guard count > 0 else { throw failure("Code line cannot fit the editor.") }
                rows.append(Row(text: styled.attributedSubstring(from: NSRange(location: offset, length: count)), sourceLine: popup.firstLine + index, continuation: offset > 0))
                offset += count
            }
        }
        let height = 62 + 48 + Int(lineHeight) * rows.count
        guard height <= 890 else { throw failure("Code excerpt is too tall (\(height)px); select fewer lines.") }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("Cannot allocate editor image.") }
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        context.addPath(CGPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 16, cornerHeight: 16, transform: nil)); context.clip()
        context.setFillColor(color(0xFFFFFF).cgColor); context.fill(bounds)
        context.setFillColor(color(0xF6F7F9).cgColor); context.fill(CGRect(x: 0, y: height - 62, width: width, height: 62))
        context.setFillColor(color(0xFAFBFD).cgColor); context.fill(CGRect(x: 0, y: 0, width: 66, height: height - 62))
        context.setStrokeColor(color(0xE3E6EC).cgColor); context.setLineWidth(1)
        context.move(to: CGPoint(x: 0, y: height - 62)); context.addLine(to: CGPoint(x: width, y: height - 62)); context.strokePath()
        for (index, value) in [UInt32(0xFF5F57), 0xFEBC2E, 0x28C840].enumerated() {
            context.setFillColor(color(value).cgColor)
            context.fillEllipse(in: CGRect(x: 23 + index * 26, y: height - 38, width: 14, height: 14))
        }
        let title = NSAttributedString(string: URL(fileURLWithPath: popup.sourcePath).lastPathComponent, attributes: [.font: CTFontCreateWithName("HelveticaNeue-Medium" as CFString, 21, nil), .foregroundColor: color(0x334155).cgColor])
        let titleLine = CTLineCreateWithAttributedString(title)
        context.textPosition = CGPoint(x: (CGFloat(width) - CGFloat(CTLineGetTypographicBounds(titleLine, nil, nil, nil))) / 2, y: CGFloat(height) - 39)
        CTLineDraw(titleLine, context)
        for (index, row) in rows.enumerated() {
            let baseline = CGFloat(height) - 62 - 29 - fontSize - CGFloat(index) * lineHeight
            if popup.highlightLines.contains(row.sourceLine) {
                context.setFillColor(color(0xEDF3FF).cgColor)
                context.fill(CGRect(x: 66, y: baseline - 8, width: CGFloat(width) - 66, height: lineHeight))
            }
            if !row.continuation {
                let number = NSAttributedString(string: String(row.sourceLine), attributes: [.font: CTFontCreateWithName("Menlo-Regular" as CFString, 17, nil), .foregroundColor: color(0x68778F).cgColor])
                let line = CTLineCreateWithAttributedString(number)
                context.textPosition = CGPoint(x: 52 - CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)), y: baseline + 1)
                CTLineDraw(line, context)
            }
            context.textPosition = CGPoint(x: codeX + (row.continuation ? 24 : 0), y: baseline)
            CTLineDraw(CTLineCreateWithAttributedString(row.text), context)
        }
        context.setStrokeColor(color(0xD6DBE4).cgColor); context.setLineWidth(1)
        context.addPath(CGPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 16, cornerHeight: 16, transform: nil)); context.strokePath()
        guard let image = context.makeImage() else { throw failure("Cannot encode editor image.") }
        return image
    }
    @MainActor static func syntax(_ source: String, size: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(string: source, attributes: [.font: CTFontCreateWithName("Menlo-Regular" as CFString, size, nil), .foregroundColor: color(0x243247).cgColor])
        let patterns: [(String, UInt32)] = [
            (#"\b[A-Z][A-Za-z0-9_]*\b"#, 0x225F9B),
            (#"\b[0-9]+(?:\.[0-9]+)?\b"#, 0x79549F),
            (#"\b(?:public|private|static|func|let|var|return|guard|else|if|nil|true|false|enum|case|struct|in|some|try|catch|throw|mutating)\b"#, 0x973B8C),
            (#""(?:\\.|[^"\\])*""#, 0xA23837),
            (#"//.*$"#, 0x5C716A)
        ]
        for (pattern, value) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: source, range: NSRange(location: 0, length: result.length)) { result.addAttribute(.foregroundColor, value: color(value).cgColor, range: match.range) }
        }
        return result
    }
    @MainActor static func text(_ string: String, frame: CGRect, size: CGFloat, color value: UInt32, bold: Bool = false) -> CALayer {
        // Rasterize only the caption typography. CATextLayer's lazy backing does
        // not reliably render in a headless macOS AVFoundation export process.
        let layer = CALayer(); layer.frame = frame; layer.contentsScale = 2
        let font = CTFontCreateWithName("Manrope-Regular" as CFString, size * 2, nil)
        let selected = bold ? (CTFontCreateCopyWithSymbolicTraits(font, size * 2, nil, .boldTrait, .boldTrait) ?? font) : font
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 10
        let attributed = NSAttributedString(string: string, attributes: [.font: selected, .foregroundColor: color(value).cgColor, .paragraphStyle: paragraph])
        let width = Int(frame.width * 2), height = Int(frame.height * 2)
        if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            let setter = CTFramesetterCreateWithAttributedString(attributed)
            let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: height), transform: nil)
            let textFrame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: attributed.length), path, nil)
            CTFrameDraw(textFrame, context)
            layer.contents = context.makeImage()
        }
        return layer
    }
}
