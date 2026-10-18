import SwiftUI

struct ProfileView: View {
    @Bindable var model: AppModel
    @State private var name = ""
    @State private var goal = 10
    @State private var editing = false
    @State private var confirmingReset = false
    @State private var compactHeader = false

    private var unlockedAwards: Int { model.awards.filter(\.isUnlocked).count }
    private var currentLevelXP: Int { model.stats.xp % 100 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                LensScrollMarker()
                HStack {
                    Text("LEARNER PROFILE").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(LensTheme.teal)
                    Spacer()
                    Button(action: beginEditing) {
                        Image(systemName: "pencil").font(.headline).foregroundStyle(LensTheme.navy)
                            .frame(width: 44, height: 44).background(LensTheme.surface, in: Circle())
                    }.accessibilityLabel("Edit profile")
                }

                identityCard
                emblems
                learningRecord
                currentCourse

                HStack {
                    Label("Private on this device", systemImage: "lock.fill").font(.subheadline.bold()).foregroundStyle(LensTheme.navy)
                    Spacer()
                }.padding(18).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Button("Reset all progress", role: .destructive) { confirmingReset = true }
                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 110)
        }
        .background(LensTheme.paper).navigationBarTitleDisplayMode(.inline)
        .lensScrollSpace { compactHeader = $0 < -8 }
        .morphingTopBar(title: "Profile", symbol: "person.crop.circle.fill", collapsed: compactHeader)
        .navigationDestination(for: Course.self) { CourseDetailView(model: model, course: $0) }
        .sheet(isPresented: $editing) { editSheet }
        .confirmationDialog("Reset all progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive, action: model.resetProgress)
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently removes your local profile, lessons, XP, and awards.") }
    }

    private var identityCard: some View {
        VStack(spacing: 0) {
            AcademicBanner().frame(height: 174)
            HStack(alignment: .top, spacing: 16) {
                levelAvatar.offset(y: -48)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Level \(model.stats.level)").font(.headline.weight(.heavy))
                        Spacer()
                        Text("\(currentLevelXP)/100 XP").font(.caption.monospacedDigit().bold())
                    }
                    Text(model.snapshot.profile.displayName).font(.system(.title2, design: .rounded, weight: .heavy))
                    Text(model.snapshot.studyIntention.title).font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(LensTheme.navy).padding(.top, 15)
            }
            .padding(.horizontal, 20).padding(.bottom, 18)
        }
        .background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var levelAvatar: some View {
        ZStack {
            Circle().fill(LensTheme.surface).frame(width: 104, height: 104)
            Circle().stroke(LensTheme.border, lineWidth: 8).frame(width: 90, height: 90)
            Circle().trim(from: 0, to: model.stats.levelProgress)
                .stroke(AngularGradient(colors: [LensTheme.blue, LensTheme.pink, LensTheme.gold], center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90)).frame(width: 90, height: 90)
            Circle().fill(LensTheme.navy).frame(width: 70, height: 70)
            Text(initials).font(.title2.weight(.heavy)).foregroundStyle(LensTheme.onInk)
            Text("\(model.stats.level)").font(.caption2.monospacedDigit().bold()).foregroundStyle(LensTheme.onInk)
                .frame(width: 28, height: 28).background(LensTheme.teal, in: Circle()).overlay(Circle().stroke(.white, lineWidth: 3))
                .offset(x: 36, y: 35)
        }.frame(width: 104, height: 104)
    }

    private var emblems: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .lastTextBaseline) {
                Text("Academic Emblems").font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
                Spacer()
                NavigationLink { AwardsView(model: model) } label: {
                    HStack(spacing: 7) {
                        Text("\(unlockedAwards)/\(model.awards.count)").font(.headline.monospacedDigit().bold())
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }.foregroundStyle(LensTheme.navy)
                }.accessibilityLabel("View all awards, \(unlockedAwards) of \(model.awards.count) earned")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 18) {
                ForEach(Array(model.awards.enumerated()), id: \.element.id) { index, award in
                    emblem(award, index: index)
                }
            }
        }
    }

    private func emblem(_ award: AwardProgress, index: Int) -> some View {
        let color = [LensTheme.gold, LensTheme.pink, LensTheme.blue][index % 3]
        return VStack(spacing: 9) {
            ZStack {
                Hexagon().fill(award.isUnlocked ? color : LensTheme.border)
                Hexagon().stroke(.white.opacity(0.8), lineWidth: 5).padding(6)
                Image(systemName: award.isUnlocked ? award.symbolName : "lock.fill")
                    .font(.title2.weight(.bold)).foregroundStyle(award.isUnlocked ? LensTheme.navy : LensTheme.slate)
            }.frame(width: 82, height: 92)
            Text(award.title).font(.caption.weight(.heavy)).foregroundStyle(LensTheme.navy).multilineTextAlignment(.center).lineLimit(2).frame(minHeight: 32)
            if !award.isUnlocked {
                Text("\(award.current)/\(award.target)").font(.caption2.monospacedDigit().bold()).foregroundStyle(LensTheme.slate)
            } else {
                Text("EARNED").font(.caption2.weight(.heavy)).tracking(0.6).foregroundStyle(LensTheme.navy)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(award.title), \(award.detail), \(award.isUnlocked ? "earned" : "\(award.current) of \(award.target)")")
    }

    private var learningRecord: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Learning Record").font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
            HStack(spacing: 0) {
                recordMetric("bolt.fill", "\(model.stats.xp)", "XP")
                recordMetric("flame.fill", "\(model.stats.streakDays)", "STREAK")
                recordMetric("checkmark.seal.fill", "\(model.completedSessions.count)", "TESTS")
            }
            .padding(.vertical, 17).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func recordMetric(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(LensTheme.teal)
            Text(value).font(.title3.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
            Text(label).font(.caption2.bold()).tracking(0.7).foregroundStyle(LensTheme.slate)
        }.frame(maxWidth: .infinity)
    }

    private var currentCourse: some View {
        NavigationLink(value: model.selectedCourse) {
            HStack(spacing: 14) {
                Image(systemName: model.selectedCourse.symbolName).font(.title3.bold()).foregroundStyle(LensTheme.onInk)
                    .frame(width: 50, height: 50).background(LensTheme.navy, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT COURSE").font(.caption2.bold()).tracking(1).foregroundStyle(LensTheme.navy)
                    Text(model.selectedCourse.title).font(.headline.bold()).foregroundStyle(LensTheme.navy)
                }
                Spacer(); Text("\(Int(model.courseCompletion(model.selectedCourse.id) * 100))%").font(.headline.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
            }.padding(18).background(LensTheme.courseSurface(model.selectedCourse.subject), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }.buttonStyle(LensCardButtonStyle())
    }

    private var initials: String {
        let value = model.snapshot.profile.displayName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
        return value.isEmpty ? "L" : value
    }
    private func beginEditing() { name = model.snapshot.profile.displayName; goal = model.snapshot.profile.dailyGoalMinutes; editing = true }
    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("DISPLAY NAME") { TextField("Name", text: $name).textInputAutocapitalization(.words) }
                Section("DAILY GOAL") {
                    Picker("Minutes", selection: $goal) { ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) minutes").tag($0) } }
                }
            }
            .navigationTitle("Edit profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { model.updateProfile(name: name, dailyGoalMinutes: goal); editing = false } }
            }
        }.presentationDetents([.medium])
    }
}

private struct AcademicBanner: View {
    private let symbols = ["books.vertical.fill", "function", "atom", "graduationcap.fill", "globe.americas.fill", "pencil.and.ruler.fill"]
    private let positions: [CGPoint] = [.init(x: 0.12, y: 0.27), .init(x: 0.33, y: 0.65), .init(x: 0.54, y: 0.27), .init(x: 0.73, y: 0.64), .init(x: 0.9, y: 0.3), .init(x: 0.93, y: 0.82)]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [LensTheme.blue, LensTheme.pink.opacity(0.9), LensTheme.gold], startPoint: .topLeading, endPoint: .bottomTrailing)
                ForEach(symbols.indices, id: \.self) { index in
                    Image(systemName: symbols[index]).font(.system(size: index.isMultiple(of: 2) ? 32 : 25, weight: .bold))
                        .foregroundStyle(.white.opacity(0.78))
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -9 : 11))
                        .position(x: proxy.size.width * positions[index].x, y: proxy.size.height * positions[index].y)
                }
                Text("FIRST STATE SCHOLAR").font(.caption2.weight(.black)).tracking(1.5).foregroundStyle(LensTheme.navy)
                    .padding(.horizontal, 13).padding(.vertical, 8).background(.white.opacity(0.78), in: Capsule())
            }
        }
    }
}

private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.25), CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.25), CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)
        ]
        var path = Path(); path.move(to: points[0]); points.dropFirst().forEach { path.addLine(to: $0) }; path.closeSubpath(); return path
    }
}
