import CoreHaptics
import Foundation

@Observable
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var rollingPlayer: CHHapticAdvancedPatternPlayer?

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] _ in self?.setupEngine() }
            engine?.resetHandler = { [weak self] in
                do { try self?.engine?.start() } catch {}
            }
            try engine?.start()
        } catch {
            print("HapticManager: engine init failed — \(error)")
        }
    }

    // MARK: - Public API

    func playWallBounce() {
        play { try HapticPattern.wallBounce() }
    }

    func playThrowRelease() {
        play { try HapticPattern.throwRelease() }
    }

    func playCatchWarning() {
        play { try HapticPattern.catchWarning() }
    }

    func playPerfectCatch() {
        play { try HapticPattern.perfectCatch() }
    }

    func playMiss() {
        play { try HapticPattern.miss() }
    }

    /// Start continuous rolling rumble at given speed (0–1)
    func startRolling(intensity: Float) {
        guard let engine else { return }
        let clampedIntensity = max(0.0, min(1.0, intensity))
        guard clampedIntensity > 0.02 else { stopRolling(); return }
        do {
            let pattern = try HapticPattern.rollingContinuous(intensity: clampedIntensity)
            if rollingPlayer == nil {
                rollingPlayer = try engine.makeAdvancedPlayer(with: pattern)
                rollingPlayer?.loopEnabled = true
                try rollingPlayer?.start(atTime: CHHapticTimeImmediate)
            }
        } catch {}
    }

    func stopRolling() {
        try? rollingPlayer?.stop(atTime: CHHapticTimeImmediate)
        rollingPlayer = nil
    }

    func updateRollingIntensity(_ intensity: Float) {
        // Restart player with new intensity (simplest approach for continuous)
        stopRolling()
        if intensity > 0.02 { startRolling(intensity: intensity) }
    }

    // MARK: - Private

    private func play(pattern: () throws -> CHHapticPattern) {
        guard let engine else { return }
        do {
            let p = try pattern()
            let player = try engine.makePlayer(with: p)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
