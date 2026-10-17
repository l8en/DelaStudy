import SwiftUI

enum LensTheme {
    static let navy = Color(light: 0x101114, dark: 0xF8F8FC)
    static let paper = Color(light: 0xF2F3F8, dark: 0x11131A)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1B1E28)
    static let teal = Color(light: 0x5578E8, dark: 0x91ACFF)
    static let slate = Color(light: 0x3E4655, dark: 0xC4CAD5)
    static let gold = Color(light: 0xF28A24, dark: 0xFFA14A)
    static let pink = Color(light: 0xD96BE7, dark: 0xEA91F3)
    static let blue = Color(light: 0x84A8F5, dark: 0x7397E7)
    static let border = Color(light: 0xDDE1EB, dark: 0x343845)
    static let success = Color(light: 0x17805C, dark: 0x65D3A8)
    static let error = Color(light: 0xC4483E, dark: 0xFF958C)

    static func courseColor(_ subject: CourseSubject) -> Color {
        switch subject {
        case .history: gold
        case .mathematics: blue
        case .biology: pink
        }
    }

    static func courseSurface(_ subject: CourseSubject) -> Color {
        switch subject {
        case .history: Color(light: 0xFFE0B4, dark: 0x603C18)
        case .mathematics: Color(light: 0xAFC7FA, dark: 0x294477)
        case .biology: Color(light: 0xEDB3F3, dark: 0x65326B)
        }
    }
}

extension Color {
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((value >> 16) & 0xFF) / 255,
                green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

struct LensPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(.white)
            .background(isEnabled ? LensTheme.navy : LensTheme.slate.opacity(0.38), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct EditorialTitle: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(LensTheme.teal)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(LensTheme.navy)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SourceNote: View {
    let source: SourceReference
    var body: some View {
        Link(destination: source.url) {
            Label(source.publisher, systemImage: "arrow.up.right")
                .font(.caption.weight(.bold)).foregroundStyle(LensTheme.navy)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(LensTheme.surface, in: Capsule())
        }
        .accessibilityHint("Opens the source website")
    }
}
