import SwiftUI

struct CollegeHubView: View {
    @Bindable var model: AppModel
    @State private var compactHeader = false

    private let checklist = [
        CollegeStep(id: "interests", title: "Name three fields to explore", symbol: "safari.fill"),
        CollegeStep(id: "coursework", title: "Review your course plan", symbol: "books.vertical.fill"),
        CollegeStep(id: "college-list", title: "Compare three colleges", symbol: "building.columns.fill"),
        CollegeStep(id: "aid", title: "Learn the aid process", symbol: "dollarsign.circle.fill"),
        CollegeStep(id: "calendar", title: "Build an application calendar", symbol: "calendar")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                LensScrollMarker()
                hero
                roadmap
                collegeCourses
                resources
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 110)
        }
        .background(LensTheme.paper)
        .navigationDestination(for: Course.self) { CourseDetailView(model: model, course: $0) }
        .navigationBarTitleDisplayMode(.inline)
        .lensScrollSpace { compactHeader = $0 < -8 }
        .morphingTopBar(title: "College", symbol: "graduationcap.fill", collapsed: compactHeader)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("COLLEGE LAUNCHPAD").font(.caption.weight(.heavy)).tracking(1.2)
                Spacer()
                Image(systemName: "graduationcap.fill").font(.title2.weight(.bold))
            }
            Text("Make the next move")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
            HStack(alignment: .lastTextBaseline) {
                Text("\(model.snapshot.collegeChecklistIDs.count)/\(checklist.count)").font(.system(size: 42, weight: .heavy, design: .rounded)).monospacedDigit()
                Text("READY STEPS").font(.caption.weight(.heavy)).tracking(1)
            }
            ProgressView(value: Double(model.snapshot.collegeChecklistIDs.count), total: Double(checklist.count)).tint(LensTheme.navy)
        }
        .foregroundStyle(LensTheme.navy).padding(22)
        .background(LinearGradient(colors: [LensTheme.gold.opacity(0.88), LensTheme.pink.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var roadmap: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your launch list").font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
            ForEach(checklist) { item in
                let completed = model.snapshot.collegeChecklistIDs.contains(item.id)
                Button { withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) { model.toggleCollegeChecklistItem(item.id) } } label: {
                    HStack(spacing: 14) {
                        Image(systemName: completed ? "checkmark" : item.symbol).font(.headline.weight(.bold))
                            .foregroundStyle(completed ? LensTheme.onInk : LensTheme.navy)
                            .frame(width: 42, height: 42).background(completed ? LensTheme.success : LensTheme.paper, in: Circle())
                        Text(item.title).font(.subheadline.weight(.heavy)).foregroundStyle(LensTheme.navy)
                        Spacer()
                    }
                    .padding(12).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }.buttonStyle(LensCardButtonStyle())
            }
        }
    }

    private var collegeCourses: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("College courses").font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
                Spacer()
                Text("\(collegeCourseList.count)").font(.caption.monospacedDigit().bold()).foregroundStyle(LensTheme.navy)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(collegeCourseList) { course in
                        NavigationLink(value: course) {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(systemName: course.symbolName).font(.title3.bold()).foregroundStyle(LensTheme.onInk)
                                    .frame(width: 46, height: 46).background(LensTheme.navy, in: Circle())
                                Text(course.title).font(.headline.weight(.heavy)).foregroundStyle(LensTheme.navy).lineLimit(2)
                                Text("\(course.objectiveIDs.count) \(course.objectiveIDs.count == 1 ? "lesson" : "lessons")")
                                    .font(.caption.weight(.bold)).foregroundStyle(LensTheme.navy)
                            }
                            .padding(17).frame(width: 176, height: 170, alignment: .topLeading)
                            .background(LensTheme.courseSurface(course.subject), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                        }.buttonStyle(LensCardButtonStyle())
                    }
                }
            }
        }
    }

    private var resources: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Official tools").font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
            resource("Compare colleges", "chart.bar.doc.horizontal.fill", "https://collegescorecard.ed.gov")
            resource("Federal student aid", "dollarsign.square.fill", "https://studentaid.gov")
            resource("Plan applications", "checklist", "https://www.commonapp.org")
        }
    }

    private func resource(_ title: String, _ symbol: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: symbol).font(.headline).frame(width: 32)
                Text(title).font(.subheadline.weight(.heavy))
                Spacer(); Image(systemName: "arrow.up.right")
            }
            .foregroundStyle(LensTheme.navy).padding(17)
            .background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
    }

    private var collegeCourseList: [Course] { model.content.courses.filter { $0.level == .college } }
}

private struct CollegeStep: Identifiable {
    let id: String
    let title: String
    let symbol: String
}
