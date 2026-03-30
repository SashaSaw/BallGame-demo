import CoreMotion
import Foundation

/// Detects a throw gesture: sharp upward z-acceleration spike.
/// Z-axis is vertical (world-up) thanks to .xArbitraryZVertical reference frame,
/// so this works regardless of how the phone is oriented.
final class ThrowDetector {
    // Configuration
    var throwThreshold: Double = 1.2        // g — lowered from 1.8 for easier triggering
    var maxSpikeDuration: TimeInterval = 0.200

    // Public observable state (for stats overlay)
    var currentZAcceleration: Double = 0
    var isReady: Bool = true               // always ready — no stance required

    // Callback: peak z-accel
    var onThrowDetected: ((Double) -> Void)?

    // Private spike tracking
    private var spikeStart: TimeInterval?
    private var peakZ: Double = 0
    private var lastThrowTime: TimeInterval = 0
    private let minTimeBetweenThrows: TimeInterval = 0.8  // debounce

    func process(motion: CMDeviceMotion) {
        let z = motion.userAcceleration.z
        currentZAcceleration = z
        let now = motion.timestamp

        // Debounce: ignore throws too close together
        guard now - lastThrowTime > minTimeBetweenThrows else { return }

        if z > throwThreshold {
            // Spike started or continuing
            if spikeStart == nil { spikeStart = now; peakZ = z }
            if z > peakZ { peakZ = z }
        } else if let start = spikeStart {
            let duration = now - start
            if duration <= maxSpikeDuration && peakZ > throwThreshold {
                // Valid throw
                let velocity = peakZ * 3.5
                lastThrowTime = now
                onThrowDetected?(velocity)
            }
            spikeStart = nil
            peakZ = 0
        }
    }

    func reset() {
        spikeStart = nil
        peakZ = 0
    }
}
