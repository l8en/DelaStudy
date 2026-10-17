import SwiftUI

struct AwardsView: View {
    @Bindable var model: AppModel
    private var unlocked: Int { model.awards.filter(\.isUnlocked).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EditorialTitle(eyebrow: "Collection", title: "Awards")
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(unlocked)/\(model.awards.count)").font(.system(size: 44, weight: .heavy, design: .rounded)).foregroundStyle(LensTheme.navy)
                        Text("UNLOCKED").font(.caption.bold()).tracking(1.2).foregroundStyle(LensTheme.navy)
                    }
                    Spacer()
                    Image(systemName: "trophy.fill").font(.system(size: 38)).foregroundStyle(LensTheme.navy)
                        .frame(width: 82, height: 82).background(LensTheme.gold, in: Circle())
                }
                .padding(22).background(LensTheme.blue, in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(Array(model.awards.enumerated()), id: \.element.id) { index, award in
                        AwardTile(award: award, tint: tileColor(index))
                    }
                }
            }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 30)
        }
        .background(LensTheme.paper).navigationBarTitleDisplayMode(.inline)
    }

    private func tileColor(_ index: Int) -> Color {
        [LensTheme.gold, LensTheme.pink, LensTheme.blue][index % 3]
    }
}

private struct AwardTile: View {
    let award: AwardProgress
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: award.symbolName).font(.title2).foregroundStyle(award.isUnlocked ? .white : LensTheme.navy)
                    .frame(width: 48, height: 48).background(award.isUnlocked ? LensTheme.navy : .white.opacity(0.72), in: Circle())
                Spacer()
                if award.isUnlocked { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white).frame(width: 27, height: 27).background(LensTheme.navy, in: Circle()) }
            }
            Text(award.title).font(.headline.weight(.heavy)).foregroundStyle(LensTheme.navy)
            Spacer(minLength: 0)
            ProgressView(value: award.fraction).tint(LensTheme.navy).background(.white.opacity(0.55))
            Text(award.isUnlocked ? "UNLOCKED" : "\(award.current) / \(award.target)").font(.caption2.bold()).tracking(0.8).foregroundStyle(LensTheme.navy)
        }
        .padding(16).frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(tint.opacity(award.isUnlocked ? 0.88 : 0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(award.title), \(award.detail), \(award.isUnlocked ? "unlocked" : "\(award.current) of \(award.target)")")
    }
}
