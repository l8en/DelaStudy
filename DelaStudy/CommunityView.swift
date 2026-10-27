import SwiftUI

struct CommunityView: View {
    @Bindable var model: AppModel
    @State private var selectedPrompt: CommunityPrompt?
    @State private var draft = ""
    var body: some View {
        BearingPage(title: "Study circle", eyebrow: "Local activities & sharing") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("THIS WEEK").font(LensFont.caption2.monospaced().weight(.semibold)).tracking(1)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }.foregroundStyle(LensTheme.lime)
                Text("Explain one idea.\nLeave the notes behind.").font(LensFont.title2.weight(.semibold)).foregroundStyle(.white)
                HStack {
                    let joined = model.snapshot.joinedChallengeIDs.contains("explain-one-idea")
                    Button(joined ? "Leave challenge" : "Join challenge") { model.toggleChallenge("explain-one-idea") }
                        .font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.midnight).padding(.horizontal, 16).frame(height: 44)
                        .background(LensTheme.lime, in: RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    ShareLink(item: "Study circle: explain one idea you learned without looking at your notes. Then compare explanations with a friend.") {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(.white).frame(width: 44, height: 44)
                    }
                }
            }.padding(20).background(LensTheme.midnight, in: RoundedRectangle(cornerRadius: 16))
            SectionRule(title: "Start a conversation")
            ForEach(CommunityPrompt.prompts) { prompt in
                VStack(alignment: .leading, spacing: 10) {
                    Text(prompt.subject.uppercased()).font(LensFont.caption2.weight(.semibold)).tracking(1).foregroundStyle(LensTheme.teal)
                    Text(prompt.question).font(LensFont.headline)
                    if let response = model.snapshot.communityResponses[prompt.id] {
                        Text(response).font(LensFont.subheadline).lineLimit(4).foregroundStyle(LensTheme.slate)
                    }
                    HStack {
                        Button(model.snapshot.communityResponses[prompt.id] == nil ? "Write a response" : "Edit response") {
                            draft = model.snapshot.communityResponses[prompt.id] ?? ""; selectedPrompt = prompt
                        }.font(LensFont.subheadline.weight(.semibold)).frame(minHeight: 44)
                        Spacer()
                        ShareLink(item: prompt.question + "\n\n" + (model.snapshot.communityResponses[prompt.id] ?? "")) {
                            Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44)
                        }
                    }
                    Divider()
                }
            }
            NavigationLink { ActivityComposerView(model: model) } label: {
                WorkspaceRow(symbol: "person.2", title: "Make a study activity", detail: "A prompt for classmates or your club")
            }
            Label("Private until you choose to share.", systemImage: "lock").font(LensFont.caption).foregroundStyle(LensTheme.slate)
        }.sheet(item: $selectedPrompt) { prompt in
            NavigationStack {
                Form {
                    Section(prompt.question) {
                        TextEditor(text: $draft).frame(minHeight: 160).accessibilityLabel("Your response")
                            .onChange(of: draft) { _, value in if value.count > 600 { draft = String(value.prefix(600)) } }
                    }
                }.navigationTitle("Your response").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { selectedPrompt = nil } }
                        ToolbarItem(placement: .confirmationAction) { Button("Save") {
                            model.saveCommunityResponse(draft, for: prompt.id)
                            if model.presentedError == nil { selectedPrompt = nil }
                        } }
                    }
            }
        }
    }
}

private struct CommunityPrompt: Identifiable {
    let id: String
    let subject: String
    let question: String
    let symbol: String
    let color: Color

    static let prompts = [
        CommunityPrompt(id: "evidence", subject: "History", question: "When does one source become enough evidence?", symbol: "building.columns.fill", color: LensTheme.gold),
        CommunityPrompt(id: "models", subject: "Mathematics", question: "What makes a model useful even when it is imperfect?", symbol: "function", color: LensTheme.blue),
        CommunityPrompt(id: "systems", subject: "Science", question: "Which system becomes clearer when you trace energy or information?", symbol: "atom", color: LensTheme.pink)
    ]
}
