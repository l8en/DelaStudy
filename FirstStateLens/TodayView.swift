import SwiftUI

struct TodayView: View {
    @Bindable var model: AppModel
    @State private var compactHeader = false
    private var cardColor: Color { LensTheme.courseSurface(model.selectedCourse.subject) }
    private var demonstrated: Int { model.selectedCourseProgress.filter { $0.status == .demonstrated }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LensScrollMarker()
                profileHeader
                Text("Your learning\nroadmap")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(LensTheme.navy)
                    .fixedSize(horizontal: false, vertical: true)
                courseHero
                momentumStrip
                if let award = model.awards.first(where: { !$0.isUnlocked }) { nextAward(award) }
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 110)
        }
        .background(LensTheme.paper).navigationBarTitleDisplayMode(.inline)
        .lensScrollSpace { compactHeader = $0 < -8 }
        .morphingTopBar(title: "Today", symbol: "sparkles", collapsed: compactHeader)
    }

    private var profileHeader: some View {
        HStack(spacing: 12) {
            Text(initials).font(.headline.bold()).foregroundStyle(LensTheme.onInk)
                .frame(width: 48, height: 48).background(LensTheme.navy, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.caption.weight(.bold)).foregroundStyle(LensTheme.slate)
                Text(model.snapshot.profile.displayName).font(.headline.weight(.heavy)).foregroundStyle(LensTheme.navy)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(LensTheme.gold)
                Text("\(model.stats.streakDays)").font(.headline.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
            }
            .padding(.horizontal, 14).frame(height: 48).background(LensTheme.surface, in: Capsule())
            .accessibilityLabel("\(model.stats.streakDays) day streak")
        }
    }

    private var courseHero: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: model.selectedCourse.symbolName).font(.title2.weight(.bold)).foregroundStyle(LensTheme.onInk)
                    .frame(width: 54, height: 54).background(LensTheme.navy, in: Circle())
                Spacer()
                ZStack {
                    Circle().stroke(LensTheme.navy.opacity(0.18), lineWidth: 4)
                    Circle().trim(from: 0, to: model.courseCompletion(model.selectedCourse.id))
                        .stroke(LensTheme.navy, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
                    Text("\(demonstrated)/\(model.selectedCourse.objectiveIDs.count)").font(.caption.bold()).foregroundStyle(LensTheme.navy)
                }.frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text("\(model.selectedCourse.level.title.uppercased()) · UP NEXT").font(.caption.bold()).tracking(1).foregroundStyle(LensTheme.navy)
                Text(model.selectedCourse.title).font(.system(.title, design: .rounded, weight: .heavy)).foregroundStyle(LensTheme.navy)
                if let nextObjective { Text(nextObjective.title).font(.title3.weight(.semibold)).foregroundStyle(LensTheme.navy) }
            }
            if let nextObjective {
                NavigationLink {
                    LessonDetailView(model: model, course: model.selectedCourse, objective: nextObjective, lessonNumber: lessonNumber(for: nextObjective))
                } label: {
                    HStack { Text(demonstrated == 0 ? "Start first lesson" : "Continue course"); Spacer(); Image(systemName: "arrow.right") }
                        .font(.headline.bold()).foregroundStyle(LensTheme.onInk).padding(.horizontal, 20).frame(height: 58).background(LensTheme.navy, in: Capsule())
                }.buttonStyle(LensCardButtonStyle())
            }
        }
        .padding(22).background(cardColor, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var momentumStrip: some View {
        HStack(spacing: 0) {
            metric("bolt.fill", "\(model.stats.xp)", "XP", LensTheme.blue)
            metric("target", "\(model.todayStudyMinutes)/\(model.snapshot.profile.dailyGoalMinutes)", "MIN", LensTheme.gold)
            metric("star.fill", "LV \(model.stats.level)", "LEVEL", LensTheme.pink)
        }
        .padding(12).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func metric(_ icon: String, _ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(LensTheme.navy).frame(width: 38, height: 38).background(tint.opacity(0.7), in: Circle())
            Text(value).font(.headline.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
            Text(label).font(.caption2.bold()).tracking(0.8).foregroundStyle(LensTheme.slate)
        }.frame(maxWidth: .infinity)
    }

    private func nextAward(_ award: AwardProgress) -> some View {
        HStack(spacing: 16) {
            Image(systemName: award.symbolName).font(.title2).foregroundStyle(LensTheme.navy)
                .frame(width: 52, height: 52).background(LensTheme.gold, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("NEXT AWARD").font(.caption2.bold()).tracking(1).foregroundStyle(LensTheme.slate)
                Text(award.title).font(.headline.bold()).foregroundStyle(LensTheme.navy)
            }
            Spacer()
            Text("\(award.current)/\(award.target)").font(.headline.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
        }
        .padding(18).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
    }
    private var initials: String {
        let value = model.snapshot.profile.displayName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
        return value.isEmpty ? "L" : value
    }
    private var nextObjective: LearningObjective? {
        MasteryEngine.recommendation(content: model.content, attempts: model.snapshot.attempts, courseID: model.selectedCourse.id)?.objective
            ?? model.content.objectives(for: model.selectedCourse.id).first
    }
    private func lessonNumber(for objective: LearningObjective) -> Int {
        (model.content.objectives(for: model.selectedCourse.id).firstIndex(of: objective) ?? 0) + 1
    }
}
