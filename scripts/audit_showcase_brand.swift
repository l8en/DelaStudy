import Foundation
import AVFoundation
import Vision

/// Read-only OCR check of exported frames. A sample is evidence about sampled
/// frames, not a claim of exhaustive recognition of every pixel of a movie.
@main struct ShowcaseBrandAudit {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count >= 2 else { throw NSError(domain: "BrandAudit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Use audit VIDEO [STEP_SECONDS] [LIMIT_SECONDS]."]) }
        let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
        let duration = CMTimeGetSeconds(try await asset.load(.duration))
        let step = args.count > 2 ? Double(args[2]) ?? 1 : 1
        let limit = min(duration, args.count > 3 ? Double(args[3]) ?? duration : duration)
        let start = args.count > 4 ? Double(args[4]) ?? 0 : 0
        guard step > 0, limit > 0 else { throw NSError(domain: "BrandAudit", code: 2) }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1920, height: 1920)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        var matches: [[String: Any]] = [], samples = 0
        for seconds in stride(from: start, to: limit, by: step) {
            let frame = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600))
            let recognized: [(text: String, box: CGRect)] = try autoreleasepool {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-US"]
                request.usesLanguageCorrection = false
                request.customWords = ["DelaStudy", "First State Lens", "FirstStateLens"]
                try VNImageRequestHandler(cgImage: frame.image).perform([request])
                return (request.results ?? []).compactMap { observation in
                    guard let text = observation.topCandidates(1).first?.string else { return nil }
                    return (text, observation.boundingBox)
                }
            }
            let lines = recognized.map(\.text)
            let normalized = lines.joined(separator: " ").lowercased().filter(\.isLetter)
            if normalized.contains("firststatelens") {
                matches.append(["seconds": seconds, "matchingLines": lines.filter { line in
                    ["first", "state", "lens"].contains { line.localizedCaseInsensitiveContains($0) }
                }, "textBounds": recognized.filter { item in ["first", "state", "lens"].contains { item.text.localizedCaseInsensitiveContains($0) } }.map { item in
                    ["text": item.text, "x": item.box.minX, "y": item.box.minY, "width": item.box.width, "height": item.box.height] as [String: Any]
                }])
            }
            samples += 1
        }
        let result: [String: Any] = ["file": URL(fileURLWithPath: args[1]).lastPathComponent,
            "durationSeconds": duration, "sampleIntervalSeconds": step,
            "sampledFrames": samples, "oldBrandMatches": matches,
            "method": "Apple Vision accurate OCR, normalized old-brand phrase matching.",
            "scope": "Sampled frames only; OCR can miss text."]
        print(String(data: try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys, .prettyPrinted]), encoding: .utf8)!)
    }
}
