import AppKit
import ImageIO
import UniformTypeIdentifiers

// Original vector mark rendered into a fixed-size, opaque bitmap.
let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                        bytesPerRow: 4096, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
NSColor(calibratedRed: 0.075, green: 0.115, blue: 0.205, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
let lime = NSColor(calibratedRed: 0.84, green: 0.95, blue: 0.61, alpha: 1)
lime.setStroke()
for rect in [NSRect(x: 230, y: 230, width: 440, height: 440), NSRect(x: 350, y: 350, width: 440, height: 440)] {
    let frame = NSBezierPath(roundedRect: rect, xRadius: 30, yRadius: 30)
    frame.lineWidth = 32; frame.stroke()
}
lime.setFill()
NSBezierPath(ovalIn: NSRect(x: 477, y: 477, width: 70, height: 70)).fill()
NSGraphicsContext.restoreGraphicsState()
let output = URL(fileURLWithPath: CommandLine.arguments[1])
guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("Could not render icon") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not save icon") }
