import SwiftUI

struct AwardsView: View {
    @Bindable var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        BearingPage(title: "Achievements", eyebrow: "\(model.awards.filter(\.isUnlocked).count) earned") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 14) {
                ForEach(Array(model.awards.enumerated()), id: \.element.id) { i, award in
                    NavigationLink { AwardDetailView(model: model, award: award, index: i) } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            AchievementGlyph(index: i, earned: award.isUnlocked).frame(height: 100).frame(maxWidth: .infinity)
                            Text(award.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                            Text(award.isUnlocked ? "Earned" : "\(award.current) of \(award.target)").font(LensFont.caption.monospacedDigit()).foregroundStyle(LensTheme.slate)
                            ProgressView(value: award.fraction).tint(LensTheme.teal)
                        }.padding(16).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(LensCardButtonStyle())
                }
            }
        }
    }
}
struct AchievementGlyph: View {
    let index: Int
    let earned: Bool
    var body: some View {
        GeometryReader { g in
            let size = min(g.size.width, g.size.height)*0.8
            ZStack {
                RoundedRectangle(cornerRadius: index.isMultiple(of: 2) ? 12 : size*0.25)
                    .fill(earned ? LensTheme.midnight : LensTheme.border)
                    .frame(width: size, height: size).rotationEffect(.degrees(45))
                RoundedRectangle(cornerRadius: 8).stroke(earned ? LensTheme.lime : LensTheme.slate, lineWidth: 1)
                    .frame(width: size*0.73, height: size*0.73).rotationEffect(.degrees(45))
                if index % 3 == 0 { LensMark(color: earned ? LensTheme.lime : LensTheme.slate).frame(width: size*0.45, height: size*0.45) }
                else if index % 3 == 1 {
                    ForEach(0..<3) { i in Circle().stroke(earned ? LensTheme.lime : LensTheme.slate, lineWidth: 1.5)
                        .frame(width: size*CGFloat(2+i)/6, height: size*CGFloat(2+i)/6)
                    }
                } else {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in Rectangle().fill(earned ? LensTheme.lime : LensTheme.slate).frame(width: 4, height: size*CGFloat(i+2)/7) }
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityHidden(true)
    }
}
struct AwardDetailView: View {
    @Bindable var model: AppModel
    let award: AwardProgress
    let index: Int
    var body: some View {
        BearingPage(title: award.title, eyebrow: award.isUnlocked ? "Earned achievement" : "In your future collection") {
            AchievementGlyph(index: index, earned: award.isUnlocked).frame(height: 180)
            Text(award.detail).font(LensFont.headline)
            ProgressView(value: award.fraction).tint(LensTheme.teal)
            Text("\(award.current) recorded · \(award.target) required").font(LensFont.subheadline.monospacedDigit()).foregroundStyle(LensTheme.slate)
            if award.isUnlocked {
                Button(model.snapshot.workspace.featuredAwardIDs.contains(award.id) ? "Remove from featured" : "Feature on profile") {
                    model.updateWorkspace { w in
                        if w.featuredAwardIDs.contains(award.id) { w.featuredAwardIDs.remove(award.id) }
                        else if w.featuredAwardIDs.count < 3 { w.featuredAwardIDs.insert(award.id) }
                    }
                }.buttonStyle(LensPrimaryButtonStyle())
                    .disabled(!model.snapshot.workspace.featuredAwardIDs.contains(award.id) && model.snapshot.workspace.featuredAwardIDs.count >= 3)
                Text("Feature up to three achievements.").font(LensFont.caption).foregroundStyle(LensTheme.slate)
            }
            SectionRule(title: "Behind the achievement")
            Text("Calculated from your saved practice sessions and answers. Open your learning record to inspect the work.").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
            NavigationLink { LearningSummaryView(model: model) } label: { WorkspaceRow(symbol: "list.bullet.rectangle", title: "Learning record") }
        }
    }
}
