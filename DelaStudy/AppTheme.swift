import SwiftUI

/// Manrope is bundled under the SIL Open Font License. Every role scales with Dynamic Type.
enum LensFont {
    static func system(_ style: Font.TextStyle, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        if design == .monospaced { return .system(style, design: design).weight(weight) }
        let size: CGFloat = switch style {
        case .largeTitle: 34; case .title: 28; case .title2: 22; case .title3: 20
        case .headline, .body: 17; case .callout: 16; case .subheadline: 15
        case .footnote: 13; case .caption: 12; case .caption2: 11
        default: 17
        }
        return .custom("Manrope-Regular", size: size, relativeTo: style).weight(weight)
    }
    static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        design == .monospaced ? .system(size: size, weight: weight, design: design) : .custom("Manrope-Regular", size: size, relativeTo: .body).weight(weight)
    }
    static var largeTitle: Font { system(.largeTitle) }
    static var title: Font { system(.title) }
    static var title2: Font { system(.title2) }
    static var title3: Font { system(.title3) }
    static var headline: Font { system(.headline, weight: .semibold) }
    static var body: Font { system(.body) }
    static var callout: Font { system(.callout) }
    static var subheadline: Font { system(.subheadline) }
    static var footnote: Font { system(.footnote) }
    static var caption: Font { system(.caption) }
    static var caption2: Font { system(.caption2) }
}

enum LensTheme {
    static let navy = Color(light: 0x18233A, dark: 0xF0F3FA)
    static let paper = Color(light: 0xF5F4EF, dark: 0x10151D)
    static let surface = Color(light: 0xFFFFFF, dark: 0x192235)
    static let teal = Color(light: 0x3455D1, dark: 0xA2B5FF)
    static let slate = Color(light: 0x546078, dark: 0xB6C2D8)
    static let border = Color(light: 0xDCE1EB, dark: 0x33415B)
    static let gold = Color(light: 0x8A5608, dark: 0xF7C56F)
    static let pink = Color(light: 0x9A447D, dark: 0xE8A4CF)
    static let blue = Color(light: 0x3455D1, dark: 0xA2B5FF)
    static let success = Color(light: 0x187453, dark: 0x8DDCB6)
    static let error = Color(light: 0xB6343F, dark: 0xFFA5A9)
    static let onInk = Color(light: 0xFFFFFF, dark: 0x10182A)
    static let midnight = Color(red: 0.075, green: 0.115, blue: 0.205)
    static let lime = Color(red: 0.84, green: 0.95, blue: 0.61)
    static let accentWash = Color(light: 0xE8EDFF, dark: 0x243454)
    static let imageMat = Color(light: 0xEDEDE8, dark: 0x252A32)
    static let searchSurface = Color(light: 0xEEEFEF, dark: 0x222B39)
    static func courseColor(_ subject: CourseSubject) -> Color {
        switch subject {
        case .history, .socialScience: gold
        case .mathematics, .computerScience: teal
        case .biology, .finance: success
        case .chemistry, .english: pink
        case .physics: Color(light: 0x126E83, dark: 0x87D5E6)
        }
    }
    static func courseSurface(_ subject: CourseSubject) -> Color {
        switch subject {
        case .history, .socialScience: Color(light: 0xF2E8D5, dark: 0x3C3020)
        case .mathematics, .computerScience: accentWash
        case .biology, .finance: Color(light: 0xDFF0E8, dark: 0x193A32)
        case .chemistry, .english: Color(light: 0xF2E5EF, dark: 0x392639)
        case .physics: Color(light: 0xDDEFF4, dark: 0x153842)
        }
    }
}

extension Color {
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255)/255, green: CGFloat((value >> 8) & 255)/255, blue: CGFloat(value & 255)/255, alpha: 1)
        })
    }
}

struct LensPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduce
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(LensFont.system(.subheadline, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(enabled ? LensTheme.onInk : LensTheme.slate)
            .background(enabled ? LensTheme.navy : LensTheme.border, in: RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed && !reduce ? 0.98 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct LensCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduce ? 0.985 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct LensMark: View {
    var color: Color = LensTheme.teal
    var body: some View {
        GeometryReader { g in
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 9)
                    .stroke(color, lineWidth: 2.5)
                    .frame(width: g.size.width * 0.65, height: g.size.height * 0.65).offset(x: -3, y: 3)
                UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 9)
                    .stroke(color, lineWidth: 2.5)
                    .frame(width: g.size.width * 0.65, height: g.size.height * 0.65).offset(x: 3, y: -3)
                Circle().fill(color).frame(width: 5, height: 5)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityHidden(true)
    }
}


private struct LensScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
struct LensScrollMarker: View {
    var body: some View {
        GeometryReader { p in Color.clear.preference(key: LensScrollOffsetKey.self, value: p.frame(in: .global).minY) }.frame(height: 1)
    }
}
private struct ScrollTrackingModifier: ViewModifier {
    let onChange: (CGFloat) -> Void
    @State private var origin: CGFloat?
    func body(content: Content) -> some View {
        content.onPreferenceChange(LensScrollOffsetKey.self) { value in
            guard value.isFinite else { return }
            if origin == nil && value > 0 { origin = value }
            if let origin { onChange(value - origin) }
        }
    }
}
extension View {
    @ViewBuilder
    func lensScrollSpace(onChange: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: CGFloat.self) { geometry in
                -(geometry.contentOffset.y + geometry.contentInsets.top)
            } action: { _, value in onChange(value) }
        } else {
            modifier(ScrollTrackingModifier(onChange: onChange))
        }
    }
    func morphingTopBar(title: String, symbol: String, collapsed: Bool) -> some View {
        navigationBarTitleDisplayMode(.inline)
            .navigationTitle(collapsed ? title : "")
            .toolbarBackground(collapsed ? .visible : .hidden, for: .navigationBar)
            .toolbarBackground(LensTheme.surface, for: .navigationBar)
    }
}
struct BearingPage<Content: View>: View {
    let title: String
    let eyebrow: String
    @ViewBuilder var content: Content
    @State private var offset: CGFloat = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LensScrollMarker()
                VStack(alignment: .leading, spacing: 5) {
                    if !eyebrow.isEmpty { Text(eyebrow.uppercased()).font(LensFont.caption2.weight(.medium)).tracking(0.7).foregroundStyle(LensTheme.teal) }
                    Text(title).font(LensFont.system(.title, weight: .bold)).foregroundStyle(LensTheme.navy)
                        .scaleEffect(max(0.9, 1 + offset/1000), anchor: .leading)
                        .opacity(max(0, 1 + offset/70))
                }.accessibilityAddTraits(.isHeader)
                content
            }.padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 24)
        }.scrollDismissesKeyboard(.interactively).background(LensTheme.paper)
            .foregroundStyle(LensTheme.navy)
            .lensScrollSpace { offset = min(0, $0) }
            .morphingTopBar(title: title, symbol: "", collapsed: offset < -55)
    }
}
struct SectionRule: View {
    var number: String = ""
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(LensFont.headline).foregroundStyle(LensTheme.navy)
            Spacer(minLength: 0)
        }.accessibilityAddTraits(.isHeader)
    }
}
struct EditorialTitle: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased()).font(LensFont.caption.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.teal)
            Text(title).font(LensFont.system(.title, weight: .bold)).foregroundStyle(LensTheme.navy)
        }
    }
}
struct SourceNote: View {
    let source: SourceReference
    var body: some View {
        Link(destination: source.url) {
            Label(source.publisher, systemImage: "arrow.up.right").font(LensFont.caption.weight(.semibold))
                .foregroundStyle(LensTheme.teal).frame(minHeight: 44)
        }
    }
}
struct WorkspaceRow: View {
    let symbol: String
    let title: String
    var detail: String = ""
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(LensFont.system(size: 16, weight: .medium)).foregroundStyle(LensTheme.teal)
                .frame(width: 32, height: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                if !detail.isEmpty { Text(detail).font(LensFont.caption).foregroundStyle(LensTheme.slate) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(LensFont.caption2.weight(.bold)).foregroundStyle(LensTheme.slate)
        }.frame(minHeight: 50).contentShape(Rectangle())
    }
}
