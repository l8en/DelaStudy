import AppKit
import QuartzCore
import AVFoundation

/// Presentation-only diagrams. They explain source-backed behavior, not app UI.
struct ShowcaseDiagramNode: Codable {
    let id: String
    let label: String
    let detail: String?
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let shape: String?
    let activeFrom: Double?
    let activeUntil: Double?
}
struct ShowcaseDiagramEdge: Codable {
    let from: String
    let to: String
    let points: [[Double]]?
    let arrow: Bool?
}
struct ShowcaseDiagramPopup: Codable {
    let id: String
    let title: String
    let impact: String
    let start: Double
    let end: Double
    let width: Double
    let height: Double
    let nodes: [ShowcaseDiagramNode]
    let edges: [ShowcaseDiagramEdge]
}

@MainActor enum ShowcaseDiagrams {
    private static let ink: UInt32 = 0x18233A
    private static let blue: UInt32 = 0x3455D1
    private static func color(_ hex: UInt32) -> CGColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1).cgColor
    }

    static func install(_ diagram: ShowcaseDiagramPopup, in root: CALayer, duration: Double, preview: Bool = false) throws {
        guard diagram.start >= 0, diagram.end > diagram.start + 1, diagram.end <= duration,
              diagram.width <= 920, diagram.height <= 380 else { throw failure("Invalid diagram size or timing: \(diagram.id)") }
        let panel = CALayer()
        panel.frame = CGRect(x: preview ? 0 : 820, y: preview ? 0 : 1020 - diagram.height,
                             width: diagram.width, height: diagram.height)
        panel.opacity = preview ? 1 : 0
        let title = ShowcaseRenderer.text(diagram.title, frame: CGRect(x: 0, y: 0, width: diagram.width, height: 42), size: 27, color: ink, bold: true)
        panel.addSublayer(title)
        let nodes = Dictionary(uniqueKeysWithValues: diagram.nodes.map { ($0.id, $0) })
        for edge in diagram.edges {
            guard let source = nodes[edge.from], let target = nodes[edge.to] else { throw failure("Unknown edge in \(diagram.id)") }
            let points = edge.points?.map { CGPoint(x: $0[0], y: $0[1]) }
                ?? [CGPoint(x: source.x + source.width, y: source.y + source.height / 2), CGPoint(x: target.x, y: target.y + target.height / 2)]
            guard points.count >= 2 else { throw failure("An edge needs two points") }
            let path = CGMutablePath(); path.move(to: points[0])
            for point in points.dropFirst() { path.addLine(to: point) }
            let line = CAShapeLayer(); line.frame = panel.bounds
            line.path = path; line.fillColor = nil; line.strokeColor = color(0x8092BA)
            line.lineWidth = 2; line.lineCap = .round; line.lineJoin = .round
            panel.addSublayer(line)
            if edge.arrow != false {
                let tip = points.last!, previous = points[points.count - 2]
                let angle = atan2(tip.y - previous.y, tip.x - previous.x)
                let head = CGMutablePath(); head.move(to: tip)
                for delta in [-0.48, 0.48] {
                    head.addLine(to: CGPoint(x: tip.x - 9 * cos(angle + delta), y: tip.y - 9 * sin(angle + delta)))
                    head.move(to: tip)
                }
                let arrow = CAShapeLayer(); arrow.frame = panel.bounds; arrow.path = head
                arrow.fillColor = nil; arrow.strokeColor = color(0x8092BA); arrow.lineWidth = 2
                panel.addSublayer(arrow)
            }
        }
        for node in diagram.nodes {
            guard node.x >= 0, node.y >= 44, node.x + node.width <= diagram.width,
                  node.y + node.height <= diagram.height - 45 else { throw failure("Node outside diagram: \(diagram.id)/\(node.id)") }
            let group = CALayer(); group.frame = CGRect(x: node.x, y: node.y, width: node.width, height: node.height)
            let shape = CAShapeLayer(); shape.frame = group.bounds
            if node.shape == "junction" {
                shape.path = CGPath(ellipseIn: group.bounds, transform: nil)
                shape.fillColor = color(0x8092BA)
            } else {
                shape.path = node.shape == "circle" ? CGPath(ellipseIn: group.bounds.insetBy(dx: 1, dy: 1), transform: nil) : CGPath(roundedRect: group.bounds.insetBy(dx: 1, dy: 1), cornerWidth: node.shape == "pill" ? node.height / 2 : 12, cornerHeight: node.shape == "pill" ? node.height / 2 : 12, transform: nil)
                shape.fillColor = color(0xF7F8FC); shape.strokeColor = color(0xD4DCEB); shape.lineWidth = 1.5
                if let start = node.activeFrom, let end = node.activeUntil, !preview {
                    guard start >= diagram.start, end <= diagram.end, end > start else { throw failure("Invalid node highlight: \(node.id)") }
                    for (key, values) in [("fillColor", [color(0xF7F8FC), color(0xF7F8FC), color(0xE5EBFF), color(0xE5EBFF), color(0xF7F8FC), color(0xF7F8FC)]),
                                          ("strokeColor", [color(0xD4DCEB), color(0xD4DCEB), color(blue), color(blue), color(0xD4DCEB), color(0xD4DCEB)])] {
                        let a = CAKeyframeAnimation(keyPath: key)
                        a.keyTimes = [0, NSNumber(value: start / duration), NSNumber(value: (start + 0.14) / duration), NSNumber(value: (end - 0.14) / duration), NSNumber(value: end / duration), 1]
                        a.values = values; a.duration = duration; a.beginTime = AVCoreAnimationBeginTimeAtZero
                        a.isRemovedOnCompletion = false; a.fillMode = .both; shape.add(a, forKey: key)
                    }
                }
                let labelY = node.detail == nil ? (node.height - 28) / 2 : 9
                group.addSublayer(shape)
                group.addSublayer(ShowcaseRenderer.text(node.label,
                    frame: CGRect(x: 16, y: labelY, width: node.width - 30, height: 34), size: 23, color: ink, bold: true))
                if let detail = node.detail {
                    group.addSublayer(ShowcaseRenderer.text(detail,
                        frame: CGRect(x: 16, y: 39, width: node.width - 30, height: 28), size: 18, color: 0x425469))
                }
            }
            if node.shape == "junction" { group.addSublayer(shape) }
            panel.addSublayer(group)
        }
        panel.addSublayer(ShowcaseRenderer.text(diagram.impact,
            frame: CGRect(x: 0, y: diagram.height - 40, width: diagram.width, height: 40), size: 22, color: 0x425469))
        if !preview { ShowcaseRenderer.animatePopup(panel, start: diagram.start, end: diagram.end, duration: duration) }
        root.addSublayer(panel)
    }

    private static func failure(_ message: String) -> NSError {
        NSError(domain: "ShowcaseDiagrams", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
