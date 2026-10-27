import SwiftUI

struct SchoolPickerView: View {
    @Bindable var model: AppModel
    var selectedSchoolID: String? = nil
    var onSelect: ((String?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var county = "All counties"
    @State private var type = "All types"
    private var filtered: [SchoolRecord] {
        SchoolDirectory.schools.filter { $0.matches(query) && (county == "All counties" || $0.county == county) && (type == "All types" || $0.type == type) }
    }
    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Section {
                Button("Skip / no school") { choose(nil) }
                Button("I study at home") { choose("home") }
                Button("Outside Delaware") { choose("outside") }
            }
            }
            Section {
                DisclosureGroup("Filter schools") {
                Picker("County",selection:$county) { ForEach(["All counties","New Castle","Kent","Sussex"],id:\.self) { Text($0) } }
                Picker("Type",selection:$type) { ForEach(["All types"]+Set(SchoolDirectory.schools.map(\.type)).sorted(),id:\.self) { Text($0) } }
                    if county != "All counties" || type != "All types" { Button("Clear filters") { county = "All counties"; type = "All types" } }
                }
            }
            Section("\(filtered.count) \(filtered.count == 1 ? "school" : "schools")") {
                ForEach(filtered) { s in
                    Button { choose(s.id) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2.crop.circle").font(LensFont.title2).foregroundStyle(LensTheme.teal).frame(width: 38, height: 44)
                            VStack(alignment:.leading,spacing:4) {
                                Text(s.name).foregroundStyle(LensTheme.navy)
                                Text("\(s.municipality) · \(s.county ?? "County unavailable") · \(s.type)").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                            }
                            Spacer()
                            if s.id == (onSelect == nil ? model.snapshot.workspace.schoolID : selectedSchoolID) { Image(systemName:"checkmark").foregroundStyle(LensTheme.teal) }
                        }.padding(.vertical,5)
                    }
                }
                if filtered.isEmpty { Text("No matching schools. Clear a filter or search another name.") }
            }
            Section { DisclosureGroup("About this directory") {
                Text(SchoolDirectory.coverage)
                Text("School preference is private and self-selected. Listings do not imply enrollment verification, partnership, or curriculum approval.")
                Link("Explore Delaware Schools",destination:URL(string:"https://explore.education.delaware.gov/discover-districts-and-schools/")!)
            }.font(LensFont.footnote) }
        }.searchable(text:$query,placement:.navigationBarDrawer(displayMode: .always),prompt:"School, abbreviation or town").navigationTitle("Choose a school").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Cancel") { dismiss() } } }
    }
    private func choose(_ id:String?) {
        if let onSelect { onSelect(id); dismiss() }
        else if model.updateWorkspace({ $0.schoolID = id; $0.includeSchoolInSummary = false }) { dismiss() }
    }
}

struct SchoolWorkspaceView: View {
    @Bindable var model: AppModel
    @State private var picking = false
    private var school: SchoolRecord? { SchoolDirectory.schools.first { $0.id == model.snapshot.workspace.schoolID } }
    private var w: LearnerWorkspace { model.snapshot.workspace }
    var body: some View {
        BearingPage(title: "My school", eyebrow: "Delaware / your workspace") {
            if let school {
                VStack(alignment: .leading, spacing: 8) {
                    Text(school.name).font(LensFont.title3.weight(.semibold))
                    Text("\(school.municipality) · \(school.county ?? "Delaware")").font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
                    Text("\(school.type) · grades \(school.grades)").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    if let url = school.website { Link("Official school website", destination: url).frame(minHeight: 44) }
                    ForEach(school.resources, id: \.url) { resource in Link(resource.title, destination: resource.url).frame(minHeight: 44) }
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text(w.schoolID == "home" ? "Home study" : w.schoolID == "outside" ? "Studying outside Delaware" : "Connect your school to your study plans.")
                    .font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
            }
            Button(school == nil ? "Choose school (optional)" : "Change or remove school") { picking = true }.frame(minHeight: 44)
            SectionRule(title: "This week's goal")
            TextField("What would you like to work toward?", text: Binding(
                get: { w.weeklyGoal },
                set: { value in model.updateWorkspace { $0.weeklyGoal = String(value.prefix(300)) } }
            ), axis: .vertical).accessibilityLabel("Weekly academic goal").lineLimit(2...5).padding(14).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            Toggle("Save an assessment date", isOn: Binding(get: { w.assessmentDate != nil }, set: { value in model.updateWorkspace { $0.assessmentDate = value ? .now : nil } })).font(LensFont.subheadline)
            if w.assessmentDate != nil {
                DatePicker("Assessment", selection: Binding(get: { w.assessmentDate ?? .now }, set: { value in model.updateWorkspace { $0.assessmentDate = value } }), displayedComponents: .date)
            }
            NavigationLink { PlannerView(model: model) } label: { WorkspaceRow(symbol: "calendar", title: "Plan the work", detail: "Tasks, dates & focused study") }
            SectionRule(title: "Subjects you're taking")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125))], spacing: 8) {
                ForEach(CourseSubject.allCases, id: \.self) { subject in
                    let chosen = w.interests.contains(subject.rawValue)
                    Button {
                        model.updateWorkspace { workspace in
                            if chosen { workspace.interests.remove(subject.rawValue) } else { workspace.interests.insert(subject.rawValue) }
                        }
                    } label: {
                        Text(subject.title).font(LensFont.caption.weight(.medium)).foregroundStyle(chosen ? LensTheme.onInk : LensTheme.navy)
                            .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 8)
                            .background(chosen ? LensTheme.navy : LensTheme.surface, in: RoundedRectangle(cornerRadius: 9))
                    }.buttonStyle(.plain).accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
            ForEach(model.content.courses.filter { w.interests.contains($0.subject.rawValue) }.prefix(6)) { course in
                NavigationLink { CourseDetailView(model: model, course: course) } label: { WorkspaceRow(symbol: "arrow.up.right", title: course.title) }
            }
            NavigationLink { CollegeHubView(model: model) } label: { WorkspaceRow(symbol: "building.columns", title: "College & career planning") }
            NavigationLink { LearningSummaryView(model: model) } label: { WorkspaceRow(symbol: "square.and.arrow.up", title: "Share selected learning") }
            DisclosureGroup("Directory & subject support") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(SchoolDirectory.coverage).font(LensFont.caption)
                    Text("School selection is private and self-reported. Subject suggestions reflect your choices, not verified school offerings or a school partnership.").font(LensFont.caption)
                    if let school { Link("School source · checked \(school.verifiedOn)", destination: school.sourceURL).font(LensFont.caption).frame(minHeight: 44) }
                }.foregroundStyle(LensTheme.slate).padding(.top, 10)
            }.font(LensFont.subheadline)
        }.sheet(isPresented: $picking) { NavigationStack { SchoolPickerView(model: model) } }
    }
}

struct LearningSummaryView: View {
    @Bindable var model: AppModel
    @State private var includeSchool = false
    var body: some View {
        BearingPage(title:"Learning summary",eyebrow:"Review before sharing") {
            Toggle("Include my school",isOn:$includeSchool).disabled(!SchoolDirectory.schools.contains { $0.id == model.snapshot.workspace.schoolID })
            Text(model.learningSummary(includeSchool:includeSchool)).font(LensFont.body).lineSpacing(5).textSelection(.enabled)
            ShareLink(item:model.learningSummary(includeSchool:includeSchool)) { Label("Share this summary",systemImage:"square.and.arrow.up") }.frame(minHeight:44)
            Text("Only the text above is shared. Personal lesson notes and counselor questions stay private.").font(LensFont.footnote).foregroundStyle(LensTheme.slate)
        }
    }
}

struct ActivityComposerView: View {
    @Bindable var model: AppModel
    @State private var kind = 0
    @State private var invitation = ""
    private let templates = [
        "Weekly subject review: each person explains one idea, gives an example, and asks one question.",
        "Peer explanation: explain a difficult concept without notes. Ask your partner to identify one unclear step, then revise.",
        "College research: compare cost, route, support, and entry requirements using official sources. Bring one question for a counselor.",
        "Civics discussion: compare a claim in the Delaware ratification petition with what the primary source can actually establish.",
        "Short challenge: read one lesson, answer its practice questions independently, and compare your reasoning."
    ]
    private var shareText:String { "First State Lens · study invitation\n\(templates[kind])\nSuggested module: \(model.selectedCourse.title)\n\(invitation.trimmingCharacters(in:.whitespacesAndNewlines))\nThis invitation does not create an online group." }
    var body:some View {
        BearingPage(title:"Make a study activity",eyebrow:"For classmates, clubs & teachers") {
            Picker("Activity",selection:$kind) {
                ForEach(Array(["Weekly review","Peer explanation","College research","Civics discussion","Short challenge"].enumerated()),id:\.offset) { i,title in Text(title).tag(i) }
            }.pickerStyle(.menu)
            Text(templates[kind]).font(LensFont.headline)
            TextField("Add a time, topic or invitation",text:$invitation,axis:.vertical).textFieldStyle(.roundedBorder).onChange(of:invitation) { _,v in if v.count > 500 { invitation = String(v.prefix(500)) } }
            Text(shareText).font(LensFont.subheadline).textSelection(.enabled)
            ShareLink(item:shareText) { Label("Share activity",systemImage:"square.and.arrow.up") }.frame(minHeight:44)
        }
    }
}
