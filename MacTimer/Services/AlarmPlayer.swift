import AppKit
import AVFoundation

final class AlarmPlayer {
    private var player: AVAudioPlayer?

    func play(sound: AlertSoundId, volume: Double, muted: Bool, repeating: Bool) {
        guard !muted else {
            stop()
            return
        }
        start(sound: sound, volume: volume, repeating: repeating)
    }

    func preview(sound: AlertSoundId, volume: Double) {
        let audible = volume > 0 ? volume : 0.4
        start(sound: sound, volume: audible, repeating: false)
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func start(sound: AlertSoundId, volume: Double, repeating: Bool) {
        let wav = ToneLibrary.createWav(id: sound, volume: min(max(volume, 0), 1))
        do {
            let player = try AVAudioPlayer(data: wav)
            player.volume = 1
            player.numberOfLoops = repeating ? -1 : 0
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            AppLog.warn("Alert sound could not be played. \(type(of: error))")
        }
    }
}
