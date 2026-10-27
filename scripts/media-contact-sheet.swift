// Visual QA only: lay out the downloaded, unretouched shipping covers.
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let media = root.appendingPathComponent("Sources/FirstStateCore/Resources/CourseMedia")
let records = try JSONSerialization.jsonObject(with: Data(contentsOf: media.appendingPathComponent("catalog.json"))) as! [[String: Any]]
for page in stride(from: 0, to: records.count, by: 12) {
    let image = NSImage(size: NSSize(width: 1000, height: 720))
    image.lockFocus()
    NSColor(calibratedWhite: 0.95, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 1000, height: 720).fill()
    for (index, record) in records.dropFirst(page).prefix(12).enumerated() {
        let x = CGFloat(index % 4) * 250 + 10
        let y = CGFloat(2 - index / 4) * 240 + 40
        let source = NSImage(contentsOf: media.appendingPathComponent(record["filename"] as! String))!
        let scale = min(230 / source.size.width, 190 / source.size.height)
        source.draw(in: NSRect(x: x + (230 - source.size.width * scale) / 2, y: y + 25, width: source.size.width * scale, height: source.size.height * scale))
        (record["id"] as! NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium), .foregroundColor: NSColor.black])
    }
    image.unlockFocus()
    let representation = NSBitmapImageRep(data: image.tiffRepresentation!)!
    let data = representation.representation(using: .jpeg, properties: [.compressionFactor: 0.85])!
    let output = URL(fileURLWithPath: "/tmp/lens-contact-\(page / 12 + 1).jpg")
    try data.write(to: output)
    print(output.path)
}
