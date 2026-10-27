import AVFoundation
import Observation
import MediaPlayer
import UIKit

/// Original synthesized loops, generated off the main thread. No third-party recordings.
@MainActor @Observable
final class StudyAudio {
    var playing: StudySound = .silence
    var loading: StudySound?
    var message: String?
    var pausedSound: StudySound?
    private var player: AVAudioPlayer?
    private var generation = UUID()
    private var observers: [NSObjectProtocol] = []
    private var remoteTargets: [(MPRemoteCommand, Any)] = []
    private var stopTask: Task<Void, Never>?
    init() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if type == AVAudioSession.InterruptionType.began.rawValue {
                Task { @MainActor in self?.pause(); self?.message = "Audio interrupted. Resume when you’re ready." }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor in self?.pause(); self?.message = "Headphones disconnected. Playback paused." }
            }
        })
        let remote = MPRemoteCommandCenter.shared()
        remoteTargets.append((remote.playCommand, remote.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }; return .success
        }))
        remoteTargets.append((remote.pauseCommand, remote.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }; return .success
        }))
        remoteTargets.append((remote.stopCommand, remote.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.stop() }; return .success
        }))
        remoteTargets.append((remote.togglePlayPauseCommand, remote.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.playing == .silence { self.resume() } else { self.pause() }
            }; return .success
        }))
        remote.changePlaybackPositionCommand.isEnabled = false
        remote.nextTrackCommand.isEnabled = false; remote.previousTrackCommand.isEnabled = false
    }
    func play(_ sound: StudySound, level: Double) {
        if playing == sound && player != nil { setLevel(level); return }
        if pausedSound == sound { setLevel(level); resume(); return }
        stop()
        guard sound != .silence else { return }
        let token = UUID(); generation = token; loading = sound; message = nil
        Task {
            let data = await Task.detached(priority: .userInitiated) { Self.wave(sound) }.value
            guard generation == token else { return }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
                try AVAudioSession.sharedInstance().setActive(true)
                let next = try AVAudioPlayer(data: data)
                next.numberOfLoops = -1; next.volume = Float(min(0.01, max(0, level))); next.prepareToPlay()
                guard next.play() else { throw AudioError.unavailable }
                player = next; playing = sound; loading = nil
                next.setVolume(Float(min(0.8, max(0, level))), fadeDuration: 0.6)
                updateNowPlaying()
            } catch { loading = nil; message = "Playback is unavailable. Choose silence or try Play again." }
        }
    }
    func setLevel(_ level: Double) { player?.setVolume(Float(min(0.8, max(0, level))), fadeDuration: 0.1) }
    func pause() {
        guard playing != .silence else { return }
        pausedSound = playing; playing = .silence; player?.pause()
        updateNowPlaying()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func resume() {
        guard let sound = pausedSound, let player else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            guard player.play() else { throw AudioError.unavailable }
            playing = sound; pausedSound = nil; message = nil; updateNowPlaying()
        } catch { message = "Playback couldn’t resume. Choose a sound to try again." }
    }
    func reconcile() {
        if playing != .silence && player?.isPlaying == false { pause() }
    }
    /// Audio is the only background mode. A silent timer never keeps the app alive.
    func stop(at deadline: Date?) {
        stopTask?.cancel()
        guard let deadline else { return }
        stopTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(max(0, deadline.timeIntervalSinceNow))) }
            catch { return }
            self?.stop()
        }
    }
    private func updateNowPlaying() {
        guard let sound = playing != .silence ? playing : pausedSound else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: sound.title,
            MPMediaItemPropertyArtist: "DelaStudy · Study sounds",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: playing == .silence ? 0.0 : 1.0
        ]
        MPNowPlayingInfoCenter.default().playbackState = playing == .silence ? .paused : .playing
        let remote = MPRemoteCommandCenter.shared()
        remote.playCommand.isEnabled = playing == .silence
        remote.pauseCommand.isEnabled = playing != .silence
        remote.stopCommand.isEnabled = true; remote.togglePlayPauseCommand.isEnabled = true
    }
    func stop() {
        stopTask?.cancel(); stopTask = nil
        generation = UUID(); loading = nil; playing = .silence; pausedSound = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        let stoppedGeneration = generation
        let old = player; player = nil; old?.setVolume(0, fadeDuration: 0.25)
        Task {
            try? await Task.sleep(for: .milliseconds(280)); old?.stop()
            if generation == stoppedGeneration { try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation) }
        }
    }
    private enum AudioError: Error { case unavailable }
    nonisolated static func wave(_ sound: StudySound) -> Data {
        let rate = 22050, length = rate * 16, overlap = rate / 2
        var samples = [Double](repeating: 0, count: length + overlap)
        var seed: UInt64 = 73519
        var brown = 0.0, b0 = 0.0, b1 = 0.0, b2 = 0.0
        for i in samples.indices {
            seed = seed &* 6364136223846793005 &+ 1
            let white = Double(seed >> 32) / Double(UInt32.max) * 2 - 1
            b0 = 0.99765*b0 + white*0.099046; b1 = 0.963*b1 + white*0.2965164; b2 = 0.57*b2 + white*1.0526913
            let pink = (b0+b1+b2+white*0.1848)*0.15
            brown = (brown+white*0.02)/1.02
            let t = Double(i)/Double(rate)
            switch sound {
            case .silence: samples[i] = 0
            case .white: samples[i] = white*0.2
            case .pink: samples[i] = pink*0.4
            case .brown: samples[i] = brown*1.7
            case .rain: samples[i] = pink*(0.3+0.06*sin(t*Double.pi/4)) + white*0.025
            case .shoreline: samples[i] = (brown+pink*0.25)*(0.6+0.4*sin(t*Double.pi/4))
            case .grove:
                let bird = pow(max(0,sin(t*Double.pi/4)),28)*sin(2*Double.pi*1750*t+4*sin(2*Double.pi*3*t))*0.018
                samples[i] = brown*0.45+bird
            }
        }
        // Overlap-add: beginning follows the final sample with the same signal derivatives.
        for i in 0..<overlap {
            let x = Double(i)/Double(overlap)
            samples[i] = samples[length+i]*(1-x)+samples[i]*x
        }
        var pcm = Data()
        for sample in samples.prefix(length) {
            var v = Int16(max(-0.8,min(0.8,sample))*Double(Int16.max)).littleEndian
            withUnsafeBytes(of:&v) { pcm.append(contentsOf:$0) }
        }
        var data = Data()
        func tag(_ value: String) { data.append(contentsOf: value.utf8) }
        func uint(_ value: UInt32) { var x = value.littleEndian; withUnsafeBytes(of:&x) { data.append(contentsOf:$0) } }
        func short(_ value: UInt16) { var x = value.littleEndian; withUnsafeBytes(of:&x) { data.append(contentsOf:$0) } }
        tag("RIFF"); uint(UInt32(36+pcm.count)); tag("WAVEfmt "); uint(16); short(1); short(1)
        uint(UInt32(rate)); uint(UInt32(rate*2)); short(2); short(16); tag("data"); uint(UInt32(pcm.count)); data.append(pcm)
        return data
    }
}
