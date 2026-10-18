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
    static let onInk = Color(light: 0xFFFFFF, dark: 0x101114)

    static func courseColor(_ subject: CourseSubject) -> Color {
        switch subject {
        case .history: gold
        case .mathematics: blue
        case .biology: pink
        case .chemistry: Color(light: 0x8A58D8, dark: 0xC09AF7)
        case .physics: Color(light: 0x167D89, dark: 0x6ED2DA)
        case .english: Color(light: 0xC55575, dark: 0xF49AB5)
        case .socialScience: Color(light: 0xC56D22, dark: 0xF4AA6A)
        case .computerScience: Color(light: 0x246EC6, dark: 0x83B7F7)
        case .finance: Color(light: 0x277B50, dark: 0x77D2A4)
        }
    }

    static func courseSurface(_ subject: CourseSubject) -> Color {
        switch subject {
        case .history: Color(light: 0xFFE0B4, dark: 0x603C18)
        case .mathematics: Color(light: 0xAFC7FA, dark: 0x294477)
        case .biology: Color(light: 0xEDB3F3, dark: 0x65326B)
        case .chemistry: Color(light: 0xDCC8F7, dark: 0x493269)
        case .physics: Color(light: 0xB9E6E8, dark: 0x214F55)
        case .english: Color(light: 0xF7CAD6, dark: 0x643344)
        case .socialScience: Color(light: 0xF7D0AD, dark: 0x603A20)
        case .computerScience: Color(light: 0xBED9FA, dark: 0x27476C)
        case .finance: Color(light: 0xBFE8D2, dark: 0x264F3A)
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
            .foregroundStyle(LensTheme.onInk)
            .background(isEnabled ? LensTheme.navy : LensTheme.slate.opacity(0.38), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct LensScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct LensScrollMarker: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: LensScrollOffsetKey.self, value: proxy.frame(in: .named("lens-scroll")).minY)
        }
        .frame(height: 0)
    }
}

extension View {
    func lensScrollSpace(onChange: @escaping (CGFloat) -> Void) -> some View {
        coordinateSpace(name: "lens-scroll").onPreferenceChange(LensScrollOffsetKey.self, perform: onChange)
    }

    func morphingTopBar(title: String, symbol: String, collapsed: Bool) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            ZStack {
                HStack(spacing: 9) {
                    Image(systemName: symbol).font(.caption.weight(.heavy))
                    Text(title).font(.headline.weight(.heavy))
                }
                .foregroundStyle(LensTheme.navy)
                .padding(.horizontal, 16).frame(height: 42)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(LensTheme.border.opacity(0.8)))
                .shadow(color: LensTheme.navy.opacity(0.12), radius: 14, y: 7)
                .accessibilityElement(children: .combine)
                .scaleEffect(collapsed ? 1 : 0.94)
                .opacity(collapsed ? 1 : 0.88)
                .accessibilityLabel(title)
            }
            .frame(maxWidth: .infinity).frame(height: 56)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: collapsed)
        .toolbarBackground(collapsed ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(LensTheme.paper.opacity(0.94), for: .navigationBar)
    }
}

struct LensCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .brightness(configuration.isPressed ? -0.025 : 0)
            .shadow(color: LensTheme.navy.opacity(configuration.isPressed ? 0.04 : 0.09), radius: configuration.isPressed ? 2 : 10, y: configuration.isPressed ? 1 : 5)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
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
