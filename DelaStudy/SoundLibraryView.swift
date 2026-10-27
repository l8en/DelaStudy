import SwiftUI

struct SoundLibraryView: View {
    @Bindable var model: AppModel
    @State private var favoritesOnly = false
    @State private var level = 0.2
    private var audio: StudyAudio { model.focus.audio }
    private var sounds: [StudySound] { StudySound.allCases.filter { !favoritesOnly || model.snapshot.workspace.favoriteSounds.contains($0) } }
    var body: some View {
        BearingPage(title:"Study sounds",eyebrow:"Choose your atmosphere") {
            Toggle("Favorites only",isOn:$favoritesOnly).font(LensFont.subheadline)
            ForEach(sounds,id:\.self) { sound in
                HStack(spacing:14) {
                    SoundGlyph(sound: sound, isPlaying: audio.playing == sound && sound != .silence).frame(width:46,height:46)
                    Button {
                        guard model.updateWorkspace({ $0.sound = sound }) else { return }
                        if audio.playing == sound && sound != .silence { audio.pause() }
                        else { audio.play(sound,level:level); model.focus.syncAudioDeadline() }
                    } label: {
                        VStack(alignment:.leading,spacing:4) {
                            Text(sound.title).font(LensFont.headline)
                            Text(audio.loading == sound ? "Preparing audio…" : audio.playing == sound && sound != .silence ? "Playing · tap to pause" : audio.pausedSound == sound ? "Paused · tap to resume" : sound.detail).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        }.frame(maxWidth:.infinity,minHeight:56,alignment:.leading)
                    }.buttonStyle(.plain).accessibilityLabel("\(sound.title), \(audio.playing == sound ? "pause" : "preview and select")")
                    if model.snapshot.workspace.sound == sound { Image(systemName:"checkmark").foregroundStyle(LensTheme.teal).accessibilityLabel("Selected") }
                    Button {
                        model.updateWorkspace { w in if w.favoriteSounds.contains(sound) { w.favoriteSounds.remove(sound) } else { w.favoriteSounds.insert(sound) } }
                    } label: { Image(systemName:model.snapshot.workspace.favoriteSounds.contains(sound) ? "star.fill" : "star").frame(width:44,height:44) }.accessibilityLabel("Favorite \(sound.title)")
                }
                Divider()
            }
            if sounds.isEmpty { Text("No favorites yet. Turn off the filter and star a sound.").font(LensFont.subheadline) }
            VStack(alignment:.leading,spacing:12) {
                HStack { Text("Level"); Spacer(); Text("\(Int(level*100))%").monospacedDigit() }
                Slider(value:$level,in:0...0.8,onEditingChanged:{ editing in if !editing { model.updateWorkspace { $0.soundLevel = level } } }).accessibilityLabel("Sound level")
                    .onChange(of:level) { _,v in audio.setLevel(v) }
                Button("Stop sound",systemImage:"stop.fill") { audio.stop() }.frame(minHeight:44).disabled(audio.playing == .silence && audio.loading == nil && audio.pausedSound == nil)
                if let message = audio.message { Text(message).font(LensFont.subheadline).foregroundStyle(LensTheme.error) }
                Toggle("Stop at interval end",isOn:Binding(get:{model.snapshot.workspace.stopSoundAtEnd},set:{v in model.updateWorkspace { $0.stopSoundAtEnd = v }}))
                Toggle("Pause before lesson video",isOn:Binding(get:{model.snapshot.workspace.pauseSoundForVideo},set:{v in model.updateWorkspace { $0.pauseSoundForVideo = v }}))
            }.font(LensFont.subheadline)
            NavigationLink("Research & sources") { SoundResearchView() }.frame(minHeight:44)
            NavigationLink { StudyResetView() } label: { WorkspaceRow(symbol: "circle.dotted", title: "One-minute reset") }
            TextField("Optional reflection after studying",text:Binding(get:{model.snapshot.workspace.soundReflection},set:{v in model.updateWorkspace { $0.soundReflection = String(v.prefix(400)) }}),axis:.vertical).textFieldStyle(.roundedBorder)
        }
        .onAppear { level = model.snapshot.workspace.soundLevel }
        .onChange(of: model.snapshot.workspace.stopSoundAtEnd) { _, _ in model.focus.syncAudioDeadline() }
        .onDisappear { if level != model.snapshot.workspace.soundLevel { model.updateWorkspace { $0.soundLevel = level } } }
        .toolbar { ToolbarItem(placement:.topBarTrailing) { NavigationLink { SoundResearchView() } label: { Image(systemName:"info.circle").frame(width:44,height:44) }.accessibilityLabel("Research and sources") } }
    }
}
private struct SoundGlyph: View {
    let sound: StudySound
    let isPlaying: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var tint: Color {
        switch sound {
        case .brown: Color(red: 0.62, green: 0.35, blue: 0.18)
        case .pink: Color(red: 0.73, green: 0.24, blue: 0.46)
        case .rain, .shoreline: Color(red: 0.17, green: 0.43, blue: 0.71)
        default: LensTheme.teal
        }
    }
    var body: some View {
        // Playback feedback, not a measured audio spectrum. Paused rows do no work.
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !isPlaying || reduceMotion)) { timeline in
            Canvas { context, size in
                let time = isPlaying && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : 0
                for index in 0..<7 {
                    let x = size.width * CGFloat(index + 1) / 8
                    let wave = (sin(time * 7.2 + Double(index) * 1.1) + 1) / 2
                    let amplitude = sound == .silence ? 0.025 : isPlaying ? 0.09 + wave * 0.29 : 0.07 + Double(index % 3) * 0.055
                    var bar = Path()
                    bar.move(to: CGPoint(x: x, y: size.height * (0.5 - amplitude)))
                    bar.addLine(to: CGPoint(x: x, y: size.height * (0.5 + amplitude)))
                    context.stroke(bar, with: .color(tint), style: StrokeStyle(lineWidth: isPlaying ? 3 : 2, lineCap: .round))
                }
            }
        }
        .background(tint.opacity(isPlaying ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(isPlaying ? 0.45 : 0), lineWidth: 1.5))
        .accessibilityHidden(true)
    }
}
struct SoundResearchView: View {
    var body: some View {
        BearingPage(title:"Research & sources",eyebrow:"Sound, attention & breaks") {
            Text("Sound affects people differently. Explore the research and choose what works for your study session.").font(LensFont.headline)
            entry("Nigg and colleagues · 2024",question:"Can white or pink noise affect laboratory attention tasks?",body:"A meta-analysis of 13 studies included 335 children and college-age young adults with ADHD or elevated symptoms. White/pink noise showed a small benefit in this group; comparison groups without ADHD showed a negative effect. No brown-noise studies were found. Tasks and sound levels varied. These findings do not validate this app or imply better grades.",decision:"Silence is the default; sounds are optional. We make no benefit claim for brown noise or natural textures.",url:"https://pubmed.ncbi.nlm.nih.gov/38428577/")
            entry("Rijmen & Wiersema · 2024",question:"Is random noise necessary for a task benefit?",body:"Sixty neurotypical adults with self-reported ADHD traits completed a slow two-choice reaction-time task with pink noise, a 100 Hz tone, and silence. Those with elevated traits improved with either auditory condition. Pink noise did not improve the Attention Network Test’s executive network measure. The adult laboratory sample and indirect mechanism measure limit generalization.",decision:"We do not promise a special noise mechanism. Your sound preference is a personal observation.",url:"https://biblio.ugent.be/publication/01JB1Z8FCP5NSYM3NS1ZGSNWM5")
            entry("Albulescu and colleagues · 2022",question:"What do short breaks change?",body:"A meta-analysis combined 22 independent samples (2,335 participants), including work and student tasks. Breaks of ten minutes or less produced small improvements in vigor and fatigue; the overall performance effect was not statistically significant. Demanding work may need longer recovery. This does not establish 25/5 as an optimal schedule.",decision:"Work and break durations are editable, and breaks can be skipped.",url:"https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0272460")
            entry("Roediger & Karpicke · 2006",question:"Why recall before rereading?",body:"Experiments using prose passages found that retrieving studied material improved delayed retention compared with repeated studying, even when restudying felt more fluent. This supports including retrieval opportunities; it does not establish a guaranteed effect for every subject or validate this app’s particular labs.",decision:"Each new unit pairs readings with written recall and a comparison step. Completion and assessed mastery stay separate.",url:"https://pubmed.ncbi.nlm.nih.gov/16507066/")
            entry("Yilmaz Balban and colleagues · 2023",question:"Can brief breathing practices support a calmer pause?",body:"A remote randomized trial compared daily five-minute breathing practices with mindfulness over about a month. Some practices improved mood and reduced respiratory rate. The study did not test this app’s one-minute 4/6 pacer, school performance, or a promise of better concentration.",decision:"The gentle pacer is optional and unscored. It uses no breath holds; normal breathing and silence are always alternatives.",url:"https://pmc.ncbi.nlm.nih.gov/articles/PMC9873947/")
            SectionRule(title:"Audio provenance")
            Text("All textures are original signal synthesis in First State Lens. White, pink and brown are filtered noise; rain, shoreline and grove are artistic synthesized environments. No recordings or third-party audio licenses are used. Playback starts only by your choice.").font(LensFont.subheadline)
            Text("Sources reviewed 24 October 2026. Product choices and personal reflections are separate from published evidence.").font(LensFont.footnote).foregroundStyle(LensTheme.slate)
        }
    }
    private func entry(_ title:String,question:String,body:String,decision:String,url:String)->some View {
        VStack(alignment:.leading,spacing:12) {
            Text(title).font(LensFont.headline); Text(question).font(LensFont.subheadline.weight(.semibold))
            Text(body).lineSpacing(4); Text("Product decision: \(decision)").font(LensFont.subheadline)
            Link("Read publication",destination:URL(string:url)!).frame(minHeight:44)
            Divider()
        }
    }
}
