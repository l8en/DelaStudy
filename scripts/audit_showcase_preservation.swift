import Foundation
import AVFoundation
import CoreGraphics

/// Read-only frame comparison. Re-encoding is not pixel-identical; source-file
/// hashes plus equal-time phone crops establish the preservation boundary.
@main struct ShowcasePreservationAudit {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 3 else { throw NSError(domain: "Audit", code: 1) }
        let assets = args.dropFirst().map { AVURLAsset(url: URL(fileURLWithPath: $0)) }
        let generators = assets.map { asset in
            let g = AVAssetImageGenerator(asset: asset)
            g.appliesPreferredTrackTransform = true
            g.requestedTimeToleranceBefore = .zero; g.requestedTimeToleranceAfter = .zero
            return g
        }
        let durations = try await assets.asyncMap { CMTimeGetSeconds(try await $0.load(.duration)) }
        guard abs(durations[0] - durations[1]) < 0.001 else { throw NSError(domain: "Audit", code: 2) }
        let crop = CGRect(x: 135, y: 40, width: 525, height: 1000)
        var results: [[String: Double]] = []
        for seconds in stride(from: 0.5, to: durations[0], by: 1) {
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            let a = try await generators[0].image(at: time)
            let b = try await generators[1].image(at: time)
            let metrics: (Double, Double) = try autoreleasepool {
                let left = try pixels(a.image, crop: crop), right = try pixels(b.image, crop: crop)
                guard left.count == right.count else { throw NSError(domain: "Audit", code: 3) }
                var squared = 0.0, absolute = 0.0
                for index in left.indices where index % 4 != 3 {
                    let difference = Double(Int(left[index]) - Int(right[index]))
                    squared += difference * difference; absolute += abs(difference)
                }
                let count = Double(left.count / 4 * 3)
                return (squared == 0 ? 100 : 10 * log10(255 * 255 / (squared / count)), absolute / count)
            }
            let delta = abs(CMTimeGetSeconds(a.actualTime - b.actualTime))
            guard delta < 1.0 / 30 + 0.001, metrics.0 > 35 else {
                throw NSError(domain: "Audit", code: 4, userInfo: [NSLocalizedDescriptionKey: "Phone crop differs at \(seconds)s: PSNR \(metrics.0), time delta \(delta)"])
            }
            results.append(["seconds": seconds, "psnrDB": metrics.0, "meanAbsoluteChannelDifference": metrics.1, "frameTimeDeltaSeconds": delta])
        }
        let report: [String: Any] = ["durationSeconds": durations[0], "sampledFrames": results.count,
            "sampleIntervalSeconds": 1, "phoneCrop": ["x": 135, "y": 40, "width": 525, "height": 1000],
            "minimumPSNRdB": results.map { $0["psnrDB"]! }.min()!,
            "averagePSNRdB": results.reduce(0) { $0 + $1["psnrDB"]! } / Double(results.count),
            "maximumMeanAbsoluteChannelDifference": results.map { $0["meanAbsoluteChannelDifference"]! }.max()!,
            "maximumFrameTimeDeltaSeconds": results.map { $0["frameTimeDeltaSeconds"]! }.max()!,
            "scope": "Equal-time phone crop samples of approved and revised exports. Small pixel differences from video re-encoding are expected. This is not a claim of lossless or exhaustive pixel identity.", "samples": results]
        print(String(data: try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys, .prettyPrinted]), encoding: .utf8)!)
    }
    static func pixels(_ image: CGImage, crop: CGRect) throws -> [UInt8] {
        guard let section = image.cropping(to: crop) else { throw NSError(domain: "Audit", code: 5) }
        let width = section.width, height = section.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let valid = bytes.withUnsafeMutableBytes { memory -> Bool in
            guard let c = CGContext(data: memory.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            c.draw(section, in: CGRect(x: 0, y: 0, width: width, height: height)); return true
        }
        guard valid else { throw NSError(domain: "Audit", code: 6) }
        return bytes
    }
}
private extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values: [T] = []; for element in self { values.append(try await transform(element)) }; return values
    }
}
