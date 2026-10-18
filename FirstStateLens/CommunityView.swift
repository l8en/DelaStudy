import SwiftUI

struct CommunityView: View {
    @Bindable var model: AppModel
    @State private var compactHeader = false
    @State private var selectedPrompt: CommunityPrompt?
    @State private var draft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LensScrollMarker()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("STUDY CIRCLE").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(LensTheme.teal)
                        Text("Learn together")
                            .font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundStyle(LensTheme.navy)
                    }
                    Spacer()
                    Image(systemName: "person.3.fill").font(.title2.weight(.bold)).foregroundStyle(LensTheme.onInk)
                        .frame(width: 58, height: 58).background(LensTheme.navy, in: Circle())
                }

                weeklyChallenge

                Text("Discussion starters").font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
                ForEach(CommunityPrompt.prompts) { prompt in
                    promptCard(prompt)
                }

                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill").foregroundStyle(LensTheme.success)
                    Text("Your writing stays on this device until you choose to share it.")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                }
                .padding(17).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 110)
        }
        .background(LensTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .lensScrollSpace { compactHeader = $0 < -8 }
        .morphingTopBar(title: "Community", symbol: "person.3.fill", collapsed: compactHeader)
        .sheet(item: $selectedPrompt) { prompt in responseSheet(prompt) }
    }

    private var weeklyChallenge: some View {
        let joined = model.snapshot.joinedChallengeIDs.contains("explain-one-idea")
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles").font(.title2.bold())
                Spacer()
                Text("THIS WEEK").font(.caption2.weight(.heavy)).tracking(1)
            }
            Text("Explain one idea without notes")
                .font(.system(.title2, design: .rounded, weight: .heavy))
            HStack(spacing: 10) {
                Button(joined ? "Joined" : "Join challenge") { withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { model.toggleChallenge("explain-one-idea") } }
                    .font(.subheadline.weight(.heavy)).foregroundStyle(LensTheme.onInk)
                    .padding(.horizontal, 17).frame(height: 44).background(LensTheme.navy, in: Capsule())
                ShareLink(item: "Study circle challenge: Explain one idea you learned this week without looking at your notes.") {
                    Image(systemName: "square.and.arrow.up").font(.headline).foregroundStyle(LensTheme.navy)
                        .frame(width: 44, height: 44).background(.white.opacity(0.72), in: Circle())
                }
            }
        }
        .foregroundStyle(LensTheme.navy).padding(20)
        .background(LinearGradient(colors: [LensTheme.blue, LensTheme.pink.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func promptCard(_ prompt: CommunityPrompt) -> some View {
        let response = model.snapshot.communityResponses[prompt.id]
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: prompt.symbol).font(.headline).foregroundStyle(LensTheme.navy)
                    .frame(width: 42, height: 42).background(prompt.color.opacity(0.75), in: Circle())
                Text(prompt.subject.uppercased()).font(.caption2.weight(.heavy)).tracking(1).foregroundStyle(LensTheme.navy)
                Spacer()
                if response != nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(LensTheme.success) }
            }
            Text(prompt.question).font(.headline.weight(.heavy)).foregroundStyle(LensTheme.navy)
            if let response {
                Text(response).font(.subheadline).foregroundStyle(LensTheme.navy).lineLimit(3)
            }
            HStack {
                Button(response == nil ? "Add your take" : "Edit response") {
                    draft = response ?? ""
                    selectedPrompt = prompt
                }
                .font(.subheadline.weight(.heavy)).foregroundStyle(LensTheme.navy)
                Spacer()
                ShareLink(item: "Study circle prompt: \(prompt.question)") {
                    Label("Invite", systemImage: "paperplane.fill").font(.caption.weight(.heavy)).foregroundStyle(LensTheme.navy)
                }
            }
        }
        .padding(18).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func responseSheet(_ prompt: CommunityPrompt) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(prompt.question).font(.title2.weight(.heavy)).foregroundStyle(LensTheme.navy)
                TextEditor(text: $draft).font(.body).scrollContentBackground(.hidden)
                    .padding(12).background(LensTheme.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(LensTheme.border))
                Text("\(draft.count)/600").font(.caption.monospacedDigit().bold()).foregroundStyle(LensTheme.navy).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(20).background(LensTheme.surface.ignoresSafeArea())
            .navigationTitle("Your response").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { selectedPrompt = nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.saveCommunityResponse(draft, for: prompt.id); selectedPrompt = nil }.fontWeight(.bold)
                }
            }
        }.presentationDetents([.medium, .large])
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
