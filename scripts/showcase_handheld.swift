import AppKit
import QuartzCore
import AVFoundation

/// Original code-native presentation art. The device is an iPhone 14 Pro-style
/// frame around Simulator footage, not footage of a physical phone or hand.
@MainActor enum ShowcaseHandheld {
    static let canvas = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    static func install(in root: CALayer, movie: CALayer, screen: CGRect, duration: Double, screenOverlays: [CALayer] = [], includeHand: Bool = true) throws {
        let holding = CALayer()
        holding.bounds = canvas
        holding.anchorPoint = CGPoint(x: screen.midX / canvas.width, y: screen.midY / canvas.height)
        holding.position = CGPoint(x: screen.midX, y: screen.midY)
        root.addSublayer(holding)

        if includeHand {
            let rear = try artwork { c in drawRearHand(c) }
            holding.addSublayer(imageLayer(rear))
        }

        let chassis = imageLayer(try artwork { c in drawDevice(c, screen: screen) })
        let body = screen.insetBy(dx: -19, dy: -21)
        chassis.shadowColor = NSColor.black.cgColor; chassis.shadowOpacity = 0.28
        chassis.shadowRadius = 16; chassis.shadowOffset = CGSize(width: 8, height: 10)
        chassis.shadowPath = CGPath(roundedRect: body, cornerWidth: 70, cornerHeight: 70, transform: nil)
        holding.addSublayer(chassis)

        let mask = CAShapeLayer(); mask.frame = canvas
        mask.path = CGPath(roundedRect: screen, cornerWidth: 52, cornerHeight: 52, transform: nil)
        mask.fillColor = NSColor.black.cgColor
        movie.mask = mask; holding.addSublayer(movie)
        for overlay in screenOverlays { holding.addSublayer(overlay) }

        let island = imageLayer(try artwork { c in drawIsland(c, screen: screen) })
        holding.addSublayer(island)

        let indicator = CAShapeLayer()
        indicator.path = CGPath(roundedRect: CGRect(x: screen.midX - 61, y: screen.maxY - 11, width: 122, height: 5), cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        indicator.fillColor = rgba(0x101317, 0.75)
        if duration > 136.5 && includeHand {
            let appearance = CAKeyframeAnimation(keyPath: "fillColor")
            appearance.values = [rgba(0x101317, 0.75), rgba(0x101317, 0.75), rgba(0xF8F7F2, 0.85), rgba(0xF8F7F2, 0.85), rgba(0x101317, 0.75), rgba(0x101317, 0.75)]
            appearance.keyTimes = [0, NSNumber(value: 128.6 / duration), NSNumber(value: 129 / duration), NSNumber(value: 136 / duration), NSNumber(value: 136.5 / duration), 1]
            appearance.duration = duration; appearance.beginTime = AVCoreAnimationBeginTimeAtZero
            appearance.isRemovedOnCompletion = false; appearance.fillMode = .both
            indicator.add(appearance, forKey: "screen-appearance")
        }
        if includeHand { holding.addSublayer(indicator) }

        if includeHand {
        let thumb = imageLayer(try artwork { c in drawThumb(c) })
        thumb.anchorPoint = CGPoint(x: 643 / canvas.width, y: 912 / canvas.height)
        thumb.position = CGPoint(x: 643, y: 912)
        holding.addSublayer(thumb)

        if duration > 0 {
            // Hand and phone share a single rig, so the fingers never slide
            // relative to the phone. Small thumb flexes suggest a relaxed grip.
            drift(holding, key: "transform.rotation.z", duration: duration, period: 12, amplitude: .pi / 540)
            drift(holding, key: "transform.translation.y", duration: duration, period: 9, amplitude: 1.6)
            drift(thumb, key: "transform.rotation.z", duration: duration, period: 16, amplitude: .pi / 500)
        }
        }
    }

    private static func drift(_ layer: CALayer, key: String, duration: Double, period: Double, amplitude: Double) {
        let count = Int(ceil(duration * 2))
        let animation = CAKeyframeAnimation(keyPath: key)
        animation.keyTimes = (0...count).map { NSNumber(value: Double($0) / Double(count)) }
        animation.values = (0...count).map { index in
            let t = Double(index) / Double(count) * duration
            let envelope = min(1, t / 1.2, (duration - t) / 1.2)
            return NSNumber(value: sin(t * 2 * .pi / period) * amplitude * envelope)
        }
        animation.calculationMode = .cubic
        animation.duration = duration; animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false; animation.fillMode = .both
        layer.add(animation, forKey: key)
    }

    private static func imageLayer(_ image: CGImage) -> CALayer {
        let layer = CALayer(); layer.frame = canvas; layer.contents = image
        return layer
    }
    private static func artwork(_ draw: (CGContext) -> Void) throws -> CGImage {
        guard let c = CGContext(data: nil, width: Int(canvas.width), height: Int(canvas.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw NSError(domain: "ShowcaseHandheld", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot allocate handheld artwork."])
        }
        c.translateBy(x: 0, y: canvas.height); c.scaleBy(x: 1, y: -1)
        draw(c)
        guard let image = c.makeImage() else { throw NSError(domain: "ShowcaseHandheld", code: 2) }
        return image
    }
    private static func rgba(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: alpha).cgColor
    }
    private static func round(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
        CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }
    private static func shade(_ c: CGContext, path: CGPath, colors: [UInt32], from: CGPoint, to: CGPoint) {
        c.saveGState(); c.addPath(path); c.clip()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { rgba($0) } as CFArray, locations: nil)!
        c.drawLinearGradient(gradient, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        c.restoreGState()
    }
    private static func stroke(_ c: CGContext, path: CGPath, color: UInt32, alpha: CGFloat, width: CGFloat) {
        c.setStrokeColor(rgba(color, alpha)); c.setLineWidth(width); c.setLineCap(.round)
        c.addPath(path); c.strokePath()
    }
    private static func drawDevice(_ c: CGContext, screen: CGRect) {
        let body = screen.insetBy(dx: -19, dy: -21)
        let outer = round(body, 70)
        shade(c, path: outer, colors: [0x515762, 0x242830, 0x777C83, 0x22262D, 0x61666F], from: CGPoint(x: body.minX, y: body.minY), to: CGPoint(x: body.maxX, y: body.maxY))
        stroke(c, path: outer, color: 0x0C0E12, alpha: 1, width: 1.5)
        stroke(c, path: round(body.insetBy(dx: 2.5, dy: 2.5), 68), color: 0xCFD4DC, alpha: 0.7, width: 1)
        c.setFillColor(rgba(0x06080C)); c.addPath(round(body.insetBy(dx: 6, dy: 6), 65)); c.fillPath()
        stroke(c, path: round(body.insetBy(dx: 7.5, dy: 7.5), 64), color: 0x6B7079, alpha: 0.4, width: 1)

        // Side controls, antenna breaks and the narrow top receiver.
        for (y, height) in [(184.0, 31.0), (252, 68), (336, 68)] {
            let button = round(CGRect(x: body.minX - 3.5, y: y, width: 5, height: height), 2)
            shade(c, path: button, colors: [0x737984, 0x242832], from: CGPoint(x: body.minX - 4, y: y), to: CGPoint(x: body.minX + 2, y: y))
        }
        let power = round(CGRect(x: body.maxX - 1, y: 275, width: 4.5, height: 103), 2)
        shade(c, path: power, colors: [0x20242C, 0x868B92], from: CGPoint(x: body.maxX - 1, y: 275), to: CGPoint(x: body.maxX + 4, y: 275))
        c.setFillColor(rgba(0xABB0B7, 0.55))
        for y in [body.minY + 92, body.maxY - 93] {
            c.fill(CGRect(x: body.minX, y: y, width: 5.5, height: 2.5)); c.fill(CGRect(x: body.maxX - 5.5, y: y, width: 5.5, height: 2.5))
        }
        c.setFillColor(rgba(0x040507)); c.addPath(round(CGRect(x: screen.midX - 28, y: body.minY + 8, width: 56, height: 2.5), 1.25)); c.fillPath()
    }
    private static func drawIsland(_ c: CGContext, screen: CGRect) {
        let pill = CGRect(x: screen.midX - 61, y: screen.minY + 11, width: 122, height: 34)
        c.setFillColor(rgba(0x030406)); c.addPath(round(pill, 17)); c.fillPath()
        stroke(c, path: round(pill.insetBy(dx: 0.5, dy: 0.5), 16.5), color: 0x242830, alpha: 0.55, width: 0.8)
        let lens = CGRect(x: pill.maxX - 24, y: pill.midY - 6, width: 12, height: 12)
        c.setFillColor(rgba(0x111B2A)); c.fillEllipse(in: lens)
        c.setFillColor(rgba(0x1D2D42)); c.fillEllipse(in: lens.insetBy(dx: 2.5, dy: 2.5))
        c.setFillColor(rgba(0x8299B5, 0.45)); c.fillEllipse(in: CGRect(x: lens.minX + 3, y: lens.minY + 2, width: 2.5, height: 1.5))
    }
    private static func drawRearHand(_ c: CGContext) {
        let palm = CGMutablePath()
        palm.move(to: CGPoint(x: 445, y: 1120))
        palm.addCurve(to: CGPoint(x: 409, y: 881), control1: CGPoint(x: 464, y: 1010), control2: CGPoint(x: 437, y: 942))
        palm.addCurve(to: CGPoint(x: 430, y: 700), control1: CGPoint(x: 378, y: 813), control2: CGPoint(x: 389, y: 747))
        palm.addCurve(to: CGPoint(x: 605, y: 629), control1: CGPoint(x: 477, y: 642), control2: CGPoint(x: 557, y: 615))
        palm.addCurve(to: CGPoint(x: 672, y: 788), control1: CGPoint(x: 652, y: 645), control2: CGPoint(x: 670, y: 714))
        palm.addCurve(to: CGPoint(x: 630, y: 1120), control1: CGPoint(x: 691, y: 899), control2: CGPoint(x: 622, y: 993))
        palm.closeSubpath()
        c.saveGState(); c.setShadow(offset: CGSize(width: 9, height: 12), blur: 22, color: rgba(0x2C1A14, 0.12))
        c.setFillColor(rgba(0xC68F69)); c.addPath(palm); c.fillPath(); c.restoreGState()
        shade(c, path: palm, colors: [0xEAC29E, 0xD7A57E, 0xBD815D, 0xA6674C], from: CGPoint(x: 423, y: 705), to: CGPoint(x: 690, y: 940))
        let tendon = CGMutablePath(); tendon.move(to: CGPoint(x: 648, y: 902))
        tendon.addCurve(to: CGPoint(x: 588, y: 1051), control1: CGPoint(x: 621, y: 949), control2: CGPoint(x: 589, y: 1000))
        stroke(c, path: tendon, color: 0x956048, alpha: 0.2, width: 2)

        // Curled fingers pass behind the body and reappear along its left edge.
        for (index, item) in [(485.0, 118.0), (573, 107), (657, 113), (735, 126)].enumerated() {
            let y = item.0, x = item.1
            let finger = CGMutablePath(); finger.move(to: CGPoint(x: 171, y: y))
            finger.addCurve(to: CGPoint(x: x, y: y + 36), control1: CGPoint(x: 143, y: y - 12), control2: CGPoint(x: x - 5, y: y + 7))
            finger.addCurve(to: CGPoint(x: 139, y: y + 91), control1: CGPoint(x: x, y: y + 63), control2: CGPoint(x: x + 4, y: y + 82))
            finger.addCurve(to: CGPoint(x: 203, y: y + 67), control1: CGPoint(x: 157, y: y + 105), control2: CGPoint(x: 193, y: y + 81))
            finger.addCurve(to: CGPoint(x: 171, y: y), control1: CGPoint(x: 211, y: y + 44), control2: CGPoint(x: 200, y: y + 11)); finger.closeSubpath()
            c.saveGState(); c.setShadow(offset: CGSize(width: -2, height: 3), blur: 4, color: rgba(0x5B3527, 0.2))
            c.setFillColor(rgba(0xCA926C)); c.addPath(finger); c.fillPath(); c.restoreGState()
            shade(c, path: finger, colors: [0xF1CCAA, 0xDFAC83, 0xB97B58], from: CGPoint(x: x + 5, y: y + 17), to: CGPoint(x: 180, y: y + 86))
            let crease = CGMutablePath(); crease.move(to: CGPoint(x: x + 5, y: y + 61))
            crease.addCurve(to: CGPoint(x: 153, y: y + 77), control1: CGPoint(x: x + 12, y: y + 72), control2: CGPoint(x: 139, y: y + 78))
            stroke(c, path: crease, color: 0x996047, alpha: 0.3, width: 1.2)
            if index < 3 {
                let nail = round(CGRect(x: x + 6, y: y + 21, width: 26, height: 39), 12)
                shade(c, path: nail, colors: [0xE9C2AD, 0xD5A68B], from: CGPoint(x: x + 10, y: y + 25), to: CGPoint(x: x + 30, y: y + 60))
                stroke(c, path: nail, color: 0xAB7159, alpha: 0.25, width: 0.8)
            }
        }
        let sleeve = CGMutablePath(); sleeve.move(to: CGPoint(x: 442, y: 1051))
        sleeve.addCurve(to: CGPoint(x: 636, y: 1057), control1: CGPoint(x: 505, y: 1039), control2: CGPoint(x: 583, y: 1040))
        sleeve.addLine(to: CGPoint(x: 657, y: 1120)); sleeve.addLine(to: CGPoint(x: 429, y: 1120)); sleeve.closeSubpath()
        shade(c, path: sleeve, colors: [0x3E4B62, 0x172437, 0x0E192A], from: CGPoint(x: 438, y: 1050), to: CGPoint(x: 647, y: 1120))
        let seam = CGMutablePath(); seam.move(to: CGPoint(x: 446, y: 1059))
        seam.addCurve(to: CGPoint(x: 632, y: 1066), control1: CGPoint(x: 515, y: 1048), control2: CGPoint(x: 578, y: 1050))
        stroke(c, path: seam, color: 0x8390A2, alpha: 0.5, width: 1.2)
    }
    private static func drawThumb(_ c: CGContext) {
        c.saveGState(); c.translateBy(x: 22, y: 0)
        let thumb = CGMutablePath(); thumb.move(to: CGPoint(x: 650, y: 914))
        thumb.addCurve(to: CGPoint(x: 670, y: 779), control1: CGPoint(x: 668, y: 878), control2: CGPoint(x: 681, y: 824))
        thumb.addCurve(to: CGPoint(x: 633, y: 699), control1: CGPoint(x: 663, y: 749), control2: CGPoint(x: 648, y: 723))
        thumb.addCurve(to: CGPoint(x: 595, y: 690), control1: CGPoint(x: 623, y: 684), control2: CGPoint(x: 605, y: 676))
        thumb.addCurve(to: CGPoint(x: 599, y: 752), control1: CGPoint(x: 581, y: 706), control2: CGPoint(x: 588, y: 732))
        thumb.addCurve(to: CGPoint(x: 609, y: 828), control1: CGPoint(x: 610, y: 776), control2: CGPoint(x: 610, y: 804))
        thumb.addCurve(to: CGPoint(x: 605, y: 902), control1: CGPoint(x: 606, y: 858), control2: CGPoint(x: 602, y: 876))
        thumb.addCurve(to: CGPoint(x: 650, y: 914), control1: CGPoint(x: 610, y: 920), control2: CGPoint(x: 636, y: 929)); thumb.closeSubpath()
        c.saveGState(); c.setShadow(offset: CGSize(width: -3, height: 3), blur: 6, color: rgba(0x432B20, 0.28))
        c.setFillColor(rgba(0xD3A07B)); c.addPath(thumb); c.fillPath(); c.restoreGState()
        shade(c, path: thumb, colors: [0xF1C9A5, 0xDFB08A, 0xBD825E], from: CGPoint(x: 596, y: 716), to: CGPoint(x: 670, y: 840))
        let nail = CGMutablePath(); nail.move(to: CGPoint(x: 601, y: 693))
        nail.addCurve(to: CGPoint(x: 624, y: 699), control1: CGPoint(x: 610, y: 685), control2: CGPoint(x: 620, y: 690))
        nail.addCurve(to: CGPoint(x: 632, y: 735), control1: CGPoint(x: 634, y: 712), control2: CGPoint(x: 640, y: 728))
        nail.addCurve(to: CGPoint(x: 608, y: 733), control1: CGPoint(x: 625, y: 744), control2: CGPoint(x: 616, y: 742))
        nail.addCurve(to: CGPoint(x: 601, y: 693), control1: CGPoint(x: 599, y: 720), control2: CGPoint(x: 594, y: 702)); nail.closeSubpath()
        shade(c, path: nail, colors: [0xF1D3BD, 0xD7A98D], from: CGPoint(x: 605, y: 693), to: CGPoint(x: 632, y: 737))
        stroke(c, path: nail, color: 0xA5745D, alpha: 0.3, width: 1)
        let crease = CGMutablePath(); crease.move(to: CGPoint(x: 610, y: 780))
        crease.addCurve(to: CGPoint(x: 648, y: 785), control1: CGPoint(x: 622, y: 773), control2: CGPoint(x: 637, y: 776))
        stroke(c, path: crease, color: 0x996148, alpha: 0.25, width: 1.2)
        c.restoreGState()
    }
}
