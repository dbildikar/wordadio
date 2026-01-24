import AVFoundation
import Foundation

/// Manages all game sound effects and background music
/// Uses AVFoundation to generate tones programmatically
class SoundManager {
    static let shared = SoundManager()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var currentNoteIndex = 0
    
    // Background music
    private var backgroundMusicPlayer: AVAudioPlayer?
    var isMuted: Bool = false {
        didSet {
            backgroundMusicPlayer?.volume = isMuted ? 0 : 0.3
            UserDefaults.standard.set(isMuted, forKey: "musicMuted")
        }
    }
    
    // Track if sound effects are muted (separate from music)
    var soundEffectsMuted: Bool = false

    // Musical notes for letter selection (E major scale - matches background music)
    private let noteFrequencies: [Float] = [
        329.63,  // E4
        369.99,  // F#4
        415.30,  // G#4
        440.00,  // A4
        493.88,  // B4
        554.37,  // C#5
        622.25   // D#5
    ]
    
    // High sparkle notes for bonus/special sounds
    private let sparkleNotes: [Float] = [
        659.25,  // E5
        830.61,  // G#5
        987.77,  // B5
        1318.51  // E6
    ]

    private init() {
        // Load mute preference
        isMuted = UserDefaults.standard.bool(forKey: "musicMuted")
        
        // Setup audio on background thread to not block UI
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.setupAudioEngine()
            self?.setupBackgroundMusic()
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)

        // Get the format from the main mixer to ensure compatibility
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            // Audio engine failed to start - app will work without sound effects
        }
    }
    
    private func setupBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "background-music", withExtension: "mp3") else {
            return
        }
        
        do {
            // Configure audio session for background music
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop forever
            backgroundMusicPlayer?.volume = isMuted ? 0 : 0.3
            backgroundMusicPlayer?.prepareToPlay()
        } catch {
            // Background music failed to setup - app will work without music
        }
    }
    
    /// Start playing background music
    func startBackgroundMusic() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.backgroundMusicPlayer?.play()
        }
    }
    
    /// Stop background music
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
    }

    /// Play a tone when a letter is selected (ascending musical scale)
    func playLetterSelectSound(index: Int) {
        let noteIndex = index % noteFrequencies.count
        let frequency = noteFrequencies[noteIndex]
        playTone(frequency: frequency, duration: 0.1, volume: 0.3)
    }

    /// Play success sound (ascending E major arpeggio)
    func playSuccessSound() {
        // Play a happy ascending arpeggio in E major (E-G#-B-E)
        let successFrequencies: [Float] = [329.63, 415.30, 493.88, 659.25]

        for (index, frequency) in successFrequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                self.playTone(frequency: frequency, duration: 0.15, volume: 0.4)
            }
        }
    }

    /// Play error sound (descending buzz)
    func playErrorSound() {
        // Play a descending "wrong" sound
        let errorFrequencies: [Float] = [400.0, 350.0, 300.0] // Descending buzz

        for (index, frequency) in errorFrequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                self.playTone(frequency: frequency, duration: 0.12, volume: 0.35)
            }
        }
    }

    /// Play completion sound (triumphant E major chord)
    func playLevelCompleteSound() {
        // E major chord arpeggio going up (E-G#-B-E-G#)
        let completeFrequencies: [Float] = [329.63, 415.30, 493.88, 659.25, 830.61]

        for (index, frequency) in completeFrequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                self.playTone(frequency: frequency, duration: 0.2, volume: 0.5)
            }
        }
    }
    
    /// Play bonus word sound (magical sparkle ascending)
    func playBonusWordSound() {
        // Sparkly ascending arpeggio
        for (index, frequency) in sparkleNotes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                self.playTone(frequency: frequency, duration: 0.12, volume: 0.35)
            }
        }
    }
    
    /// Play shuffle sound (whooshy sweep)
    func playShuffleSound() {
        // Quick ascending sweep
        let sweepFrequencies: [Float] = [200, 300, 400, 500, 600]
        for (index, frequency) in sweepFrequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.03) {
                self.playTone(frequency: frequency, duration: 0.06, volume: 0.2)
            }
        }
    }
    
    /// Play hint reveal sound (soft chime)
    func playHintSound() {
        // Gentle two-note chime
        playTone(frequency: 523.25, duration: 0.15, volume: 0.3) // C5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: 659.25, duration: 0.2, volume: 0.3) // E5
        }
    }
    
    /// Play duplicate word sound (gentler than error)
    func playDuplicateSound() {
        // Two soft descending notes
        playTone(frequency: 440.0, duration: 0.1, volume: 0.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: 392.0, duration: 0.15, volume: 0.2)
        }
    }
    
    /// Play letter deselect sound (soft descending tone)
    func playDeselectSound() {
        playTone(frequency: 350.0, duration: 0.08, volume: 0.15)
    }
    
    /// Play points earned sound (coin-like)
    func playPointsSound() {
        // Quick bright double-tap
        playTone(frequency: 880.0, duration: 0.05, volume: 0.25) // A5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.playTone(frequency: 1108.73, duration: 0.08, volume: 0.3) // C#6
        }
    }
    
    /// Play confetti celebration sound
    func playConfettiSound() {
        // Rapid ascending sparkle burst
        let confettiFrequencies: [Float] = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
        for (index, frequency) in confettiFrequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                self.playTone(frequency: frequency, duration: 0.1, volume: 0.3)
            }
        }
    }
    
    /// Play tile fill sound (soft pop)
    func playTileFillSound() {
        playTone(frequency: 600.0, duration: 0.06, volume: 0.2)
    }

    /// Play a simple tone at a given frequency (on background thread to not block UI)
    private func playTone(frequency: Float, duration: TimeInterval, volume: Float) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let engine = self.audioEngine,
                  let player = self.playerNode else { return }

            // Use the engine's format to ensure compatibility
            let format = engine.mainMixerNode.outputFormat(forBus: 0)
            let sampleRate = format.sampleRate
            let frameCount = AVAudioFrameCount(sampleRate * duration)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return
            }

            buffer.frameLength = frameCount

            // Generate sine wave for all channels
            guard let floatChannelData = buffer.floatChannelData else { return }
            let channelCount = Int(format.channelCount)

            let angularFrequency = Float(2.0 * Double.pi) * frequency / Float(sampleRate)

            for frame in 0..<Int(frameCount) {
                let sample = sin(angularFrequency * Float(frame))

                // Apply fade out to avoid clicking
                let fadeLength = Int(frameCount) / 10
                var envelope: Float = 1.0
                if frame > Int(frameCount) - fadeLength {
                    envelope = Float(Int(frameCount) - frame) / Float(fadeLength)
                }

                let finalSample = sample * volume * envelope

                // Write to all channels
                for channel in 0..<channelCount {
                    floatChannelData[channel][frame] = finalSample
                }
            }

            player.scheduleBuffer(buffer, completionHandler: nil)

            if !player.isPlaying {
                player.play()
            }
        }
    }

    /// Reset note sequence (call when clearing selection)
    func resetNoteSequence() {
        currentNoteIndex = 0
    }
}
