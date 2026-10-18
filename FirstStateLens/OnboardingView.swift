import SwiftUI

struct OnboardingView: View {
    @Bindable var model: AppModel
    @State private var page = 0
    @State private var displayName = ""
    @State private var selectedCourseID = "first-state-civics"
    @State private var intention: StudyIntention = .buildEvidenceSkills

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule().fill(index <= page ? LensTheme.teal : LensTheme.border).frame(height: 5)
                }
            }
            .padding(.horizontal, 24).padding(.top, 18)
            .accessibilityLabel("Step \(page + 1) of 3")

            TabView(selection: $page) {
                welcome.tag(0)
                courseChoice.tag(1)
                profileSetup.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Button(page == 2 ? "Start learning" : "Continue") {
                if page < 2 { withAnimation(.easeInOut) { page += 1 } }
                else { model.finishOnboarding(intention: intention, displayName: displayName, courseID: selectedCourseID) }
            }
            .buttonStyle(LensPrimaryButtonStyle()).padding(24)
        }
        .background(LensTheme.paper.ignoresSafeArea())
    }

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 8)
                ZStack {
                    RoundedRectangle(cornerRadius: 26).fill(LensTheme.teal.opacity(0.12)).frame(width: 84, height: 84)
                    Image(systemName: "sparkles.rectangle.stack.fill").font(.system(size: 38)).foregroundStyle(LensTheme.teal)
                }
                EditorialTitle(eyebrow: "Welcome to First State", title: "A study path that grows with you.")
                Text("Real courses. Clear lessons. Progress that belongs to you.")
                    .font(.headline).foregroundStyle(LensTheme.navy).lineSpacing(4)
                VStack(spacing: 12) {
                    feature("books.vertical.fill", "Choose your course", "Explore history, mathematics, and biology from high school through college.")
                    feature("point.3.connected.trianglepath.dotted", "Follow a clear path", "Lessons unlock as your understanding grows.")
                    feature("trophy.fill", "Earn meaningful awards", "XP and achievements reflect real work.")
                }
            }.padding(24)
        }
    }

    private var courseChoice: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                EditorialTitle(eyebrow: "Step 1", title: "Where should we begin?")
                ForEach(featuredCourses) { course in
                    Button { selectedCourseID = course.id } label: {
                        HStack(spacing: 16) {
                            Image(systemName: course.symbolName).font(.title2).foregroundStyle(LensTheme.courseColor(course.subject))
                                .frame(width: 46, height: 46).background(LensTheme.courseColor(course.subject).opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(course.level.title) · \(course.subject.title)".uppercased()).font(.caption2.weight(.bold)).tracking(1).foregroundStyle(LensTheme.courseColor(course.subject))
                                Text(course.title).font(.headline).foregroundStyle(LensTheme.navy)
                                Text("\(course.objectiveIDs.count) lessons · \(course.estimatedMinutes) min").font(.caption).foregroundStyle(LensTheme.slate)
                            }
                            Spacer()
                            Image(systemName: selectedCourseID == course.id ? "checkmark.circle.fill" : "circle").font(.title2)
                                .foregroundStyle(selectedCourseID == course.id ? LensTheme.teal : LensTheme.border)
                        }
                        .padding(16).background(LensTheme.courseSurface(course.subject), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(selectedCourseID == course.id ? LensTheme.navy : .clear, lineWidth: 3))
                    }
                    .buttonStyle(LensCardButtonStyle()).accessibilityAddTraits(selectedCourseID == course.id ? .isSelected : [])
                }
            }.padding(24)
        }
    }

    private var profileSetup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EditorialTitle(eyebrow: "Step 2", title: "Make the path yours.")
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT SHOULD WE CALL YOU?").font(.caption.weight(.bold)).tracking(1).foregroundStyle(LensTheme.teal)
                    TextField("First name or nickname", text: $displayName).textContentType(.nickname).textInputAutocapitalization(.words)
                        .padding(15).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(LensTheme.border))
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR FOCUS").font(.caption.weight(.bold)).tracking(1).foregroundStyle(LensTheme.teal)
                    ForEach(StudyIntention.allCases, id: \.self) { choice in
                        Button { intention = choice } label: {
                            HStack {
                                Text(choice.title).font(.body.weight(.medium)).foregroundStyle(LensTheme.navy)
                                Spacer()
                                Image(systemName: intention == choice ? "checkmark.circle.fill" : "circle").foregroundStyle(intention == choice ? LensTheme.teal : LensTheme.slate)
                            }
                            .padding(16).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
                Label("Private on this device", systemImage: "lock.fill").font(.footnote.bold()).foregroundStyle(LensTheme.navy)
            }.padding(24)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(LensTheme.gold).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(LensTheme.navy)
                Text(detail).font(.subheadline).foregroundStyle(LensTheme.navy)
            }
            Spacer(minLength: 0)
        }
    }

    private var featuredCourses: [Course] {
        let ids = ["first-state-civics", "algebra-i", "ap-biology", "geometry", "high-school-chemistry", "english-composition"]
        return ids.compactMap { model.content.course(id: $0) }
    }
}
