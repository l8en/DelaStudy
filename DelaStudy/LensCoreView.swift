import SwiftUI
import simd

/// Original low-poly optical instrument. Geometry, lighting and perspective are
/// calculated here; no generated artwork, downloaded model, or rendering engine.
struct LensCoreView: View, Animatable {
    nonisolated var progress: Double = 0
    var active = true
    var controls = true
    var contextLabel = "Learning progress"
    nonisolated var animatableData: Double { get { progress } set { progress = newValue } }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var paused = false
    @State private var visible = false
    @State private var turn = 0.0
    @GestureState private var drag = CGSize.zero
    private var moving: Bool { active && visible && !paused && !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: !moving)) { context in
            let time = moving ? context.date.timeIntervalSinceReferenceDate : 0
            Canvas { canvas, size in
                draw(in: &canvas, size: size, time: time)
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 12).updating($drag) { value, state, _ in state = value.translation }
            .onEnded { value in if !reduceMotion { turn += Double(value.translation.width) / 130 } })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lens optical core")
        .accessibilityValue("\(contextLabel), \(Int(min(1, max(0, progress)) * 100)) percent. Motion \(moving ? "on" : "off")")
        .accessibilityHint("The aperture and ring show your progress. Drag to inspect the lens.")
        .accessibilityAction(named: paused ? "Resume motion" : "Pause motion") { paused.toggle() }
        .overlay(alignment: .bottomTrailing) {
            if controls && !reduceMotion {
                Button { paused.toggle() } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill").font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LensTheme.slate).frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel(paused ? "Resume 3D motion" : "Pause 3D motion")
            }
        }
        .onAppear { visible = true }.onDisappear { visible = false }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let scale = min(size.width, size.height) * 0.34
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.46)
        let yaw = -0.32 + progress * 0.24 + sin(time * 0.52) * 0.13 + turn + (reduceMotion ? 0 : Double(drag.width) / 130)
        let pitch = -0.18 + cos(time * 0.4) * 0.06 + (reduceMotion ? 0 : max(-0.4, min(0.4, Double(drag.height) / 220)))
        let lift = sin(time * 0.8) * (reduceMotion ? 0 : 3)
        func rotated(_ p: SIMD3<Double>) -> SIMD3<Double> {
            let x = p.x * cos(yaw) + p.z * sin(yaw)
            let z = -p.x * sin(yaw) + p.z * cos(yaw)
            return SIMD3(x, p.y * cos(pitch) - z * sin(pitch), p.y * sin(pitch) + z * cos(pitch))
        }
        func point(_ p: SIMD3<Double>) -> CGPoint {
            let r = rotated(p), perspective = 3.8 / (3.8 - r.z)
            return CGPoint(x: center.x + r.x * scale * perspective, y: center.y - r.y * scale * perspective + lift)
        }
        func polygon(_ vertices: [SIMD3<Double>]) -> Path {
            Path { path in
                guard let first = vertices.first else { return }
                path.move(to: point(first)); for vertex in vertices.dropFirst() { path.addLine(to: point(vertex)) }; path.closeSubpath()
            }
        }
        let shadow = CGRect(x: center.x - scale * 0.72, y: center.y + scale * 1.14, width: scale * 1.44, height: scale * 0.16)
        context.fill(Path(ellipseIn: shadow), with: .color(LensTheme.teal.opacity(0.09)))
        // Fine construction orbit, behind the optical body.
        var orbit = Path()
        for i in 0...96 {
            let a = Double(i) / 96 * .pi * 2
            let p = point(SIMD3(cos(a) * 1.45, sin(a) * 0.23, sin(a) * 1.12))
            if i == 0 { orbit.move(to: p) } else { orbit.addLine(to: p) }
        }
        context.stroke(orbit, with: .color(LensTheme.teal.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
        let n = 8
        func ring(_ radius: Double, _ z: Double) -> [SIMD3<Double>] {
            (0..<n).map { i in let a = Double(i) / Double(n) * .pi * 2 + .pi / 8; return SIMD3(cos(a) * radius, sin(a) * radius, z) }
        }
        let front = ring(0.94, 0.25), bevel = ring(1.06, 0.02), back = ring(0.96, -0.32)
        var faces: [(vertices: [SIMD3<Double>], hue: Double)] = [(Array(back.reversed()), 0.62), (front, 0.65)]
        for i in 0..<n {
            let j = (i + 1) % n
            faces.append(([front[i], bevel[i], bevel[j], front[j]], 0.63))
            faces.append(([bevel[i], back[i], back[j], bevel[j]], 0.66))
        }
        faces.sort { a, b in a.vertices.map { rotated($0).z }.reduce(0, +) / Double(a.vertices.count) < b.vertices.map { rotated($0).z }.reduce(0, +) / Double(b.vertices.count) }
        for face in faces {
            let normal = simd_normalize(simd_cross(rotated(face.vertices[1]) - rotated(face.vertices[0]), rotated(face.vertices[2]) - rotated(face.vertices[0])))
            let light = abs(simd_dot(normal, simd_normalize(SIMD3(-0.7, 1.2, 1.4))))
            let fill = Color(hue: face.hue, saturation: 0.64, brightness: 0.4 + light * 0.5)
            let path = polygon(face.vertices)
            context.fill(path, with: .color(fill)); context.stroke(path, with: .color(.white.opacity(0.13)), lineWidth: 0.7)
        }
        // Aperture is attached to the front plane, not a 2D sticker.
        if rotated(SIMD3(0, 0, 1)).z > 0 {
            context.fill(polygon(ring(0.69, 0.265)), with: .color(Color(red: 0.07, green: 0.12, blue: 0.27)))
            for i in 0..<n {
                let a = Double(i) / Double(n) * .pi * 2
                let b = a + .pi / 4
                let opening = 0.23 + min(1, max(0, progress)) * 0.12
                let points = [SIMD3(cos(a) * 0.59, sin(a) * 0.59, 0.28), SIMD3(cos(b) * 0.59, sin(b) * 0.59, 0.28), SIMD3(cos(b + 0.8) * opening, sin(b + 0.8) * opening, 0.29), SIMD3(cos(a + 0.8) * opening, sin(a + 0.8) * opening, 0.29)]
                context.fill(polygon(points), with: .color(Color(hue: 0.62, saturation: 0.42, brightness: 0.62 + Double(i % 3) * 0.12)))
            }
            context.fill(polygon(ring(0.16 + min(1, max(0, progress)) * 0.1, 0.30)), with: .color(LensTheme.lime))
            let glint = point(SIMD3(-0.34, 0.44, 0.32))
            context.fill(Path(ellipseIn: CGRect(x: glint.x - 2, y: glint.y - 2, width: 4, height: 4)), with: .color(.white))
            var arc = Path()
            for i in 0...40 {
                let a = Double.pi / 2 - Double(i) / 40 * .pi * 2 * min(1, max(0, progress))
                let p = point(SIMD3(cos(a) * 0.79, sin(a) * 0.79, 0.29))
                if i == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
            }
            context.stroke(arc, with: .color(LensTheme.lime), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}
