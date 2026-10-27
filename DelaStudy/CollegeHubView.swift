import SwiftUI

struct CollegeHubView: View {
    @Bindable var model: AppModel
    private let steps = [("interests", "Explore fields of study"), ("coursework", "Review your course plan"), ("college-list", "Compare three colleges or routes"), ("aid", "Understand financial aid"), ("calendar", "Plan your application dates")]
    var body: some View {
        BearingPage(title: "College & next steps", eyebrow: "Your route") {
            HStack(spacing: 14) {
                Text("\(model.snapshot.collegeChecklistIDs.count)/5").font(LensFont.title2.monospacedDigit().weight(.semibold))
                Text("planning steps explored").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
            }
            ProgressView(value: Double(model.snapshot.collegeChecklistIDs.count), total: 5).tint(LensTheme.teal)
            SectionRule(title: "Build your route")
            ForEach(steps, id: \.0) { id, title in
                let done = model.snapshot.collegeChecklistIDs.contains(id)
                Button { model.toggleCollegeChecklistItem(id) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle").foregroundStyle(done ? LensTheme.success : LensTheme.slate)
                        Text(title).font(LensFont.subheadline.weight(.medium)).foregroundStyle(LensTheme.navy)
                        Spacer()
                    }.frame(minHeight: 44)
                }.buttonStyle(.plain).accessibilityLabel("\(title), \(done ? "complete" : "incomplete")")
            }
            SectionRule(title: "Your shortlist & interests")
            TextField("Fields, colleges, or routes to explore", text: Binding(get: { model.snapshot.workspace.routes }, set: { value in model.updateWorkspace { $0.routes = String(value.prefix(3000)) } }), axis: .vertical)
                .accessibilityLabel("College interests and routes").accessibilityIdentifier("college-routes")
                .lineLimit(3...8).padding(14).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            SectionRule(title: "Ask your counselor")
            TextField("Save a question for your next conversation", text: Binding(get: { model.snapshot.workspace.counselorNotes }, set: { value in model.updateWorkspace { $0.counselorNotes = String(value.prefix(3000)) } }), axis: .vertical)
                .accessibilityLabel("Questions for your counselor")
                .lineLimit(3...8).padding(14).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            ShareLink(item: "College planning\nRoutes and interests:\n\(model.snapshot.workspace.routes)\nQuestions for my counselor:\n\(model.snapshot.workspace.counselorNotes)") {
                Label("Share planning notes", systemImage: "square.and.arrow.up").font(LensFont.subheadline).frame(minHeight: 44)
            }
            SectionRule(title: "Start with trusted sources")
            resource("College Scorecard", "Compare published college information", "https://collegescorecard.ed.gov/")
            resource("Federal Student Aid", "Aid and FAFSA information", "https://studentaid.gov/")
            resource("Common App", "Explore application resources", "https://www.commonapp.org/")
            resource("Delaware college resources", "State college, aid & career information", "https://education.delaware.gov/families/college-career-life/")
            SectionRule(title: "Try college-level study")
            ForEach(model.content.courses.filter { $0.level == .college }) { course in
                NavigationLink { CourseDetailView(model: model, course: course) } label: { WorkspaceRow(symbol: "arrow.up.right", title: course.title, detail: "\(course.objectiveIDs.count) foundation modules") }
                Divider()
            }
        }
    }
    private func resource(_ title: String, _ detail: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) { WorkspaceRow(symbol: "arrow.up.right.square", title: title, detail: detail) }
    }
}
