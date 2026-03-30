import CoreMotion
import Foundation

/// Detects a throw gesture: upward z-acceleration spike while phone is roughly upright.
final class ThrowDetector {
    // Configuration
    let throwThreshold: Double = 1.8        // g
    let maxSpikeDuration: TimeInterval = 0.150
    let readyStanceDuration: TimeInterval = 0.300
    let uprightAngleLimit: Double = 30.0    // degrees from vertical

    // Public observable state
    var currentZAcceleration: Double = 0
    var isReady: Bool = false

    // Callback
    var onThrowDetected: ((Double) -> Void)?    // peak z-accel

    // Private state
    private var spikeStart: TimeInterval?
    private var peakZ: Double = 0
    private var stationaryStart: TimeInterval?
    private var lastTimestamp: TimeInterval = 0

    func process(motion: CMDeviceMotion) {
        let z = motion.userAcceleration.z
        currentZAcceleration = z
        let now = motion.timestamp
        let pitch = motion.attitude.pitch * (180 / Double.pi)  // degrees

        // Phone roughly upright: pitch near ±90°
        let pitchFromVertical = abs(abs(pitch) - 90.0)
        let phoneUpright = pitchFromVertical < uprightAngleLimit

        // Compute magnitude of total user acceleration to detect stillness
        let mag = sqrt(
            motion.userAcceleration.x * motion.userAcceleration.x +
            motion.userAcceleration.y * motion.userAcceleration.y +
            z * z
        )

        // Track ready stance (phone still for 300ms)
        if mag < 0.05 {
            if stationaryStart == nil { stationaryStart = now }
            isReady = (now - (stationaryStart ?? now)) >= readyStanceDuration
        } else {
            if mag > 0.3 { stationaryStart = nil; isReady = false }
        }

        // Spike detection: positive z (upward throw)
        if z > throwThreshold && phoneUpright && isReady {
            if spikeStart == nil { spikeStart = now; peakZ = z }
            if z > peakZ { peakZ = z }
        } else if let start = spikeStart {
            let duration = now - start
            if duration <= maxSpikeDuration && peakZ > throwThreshold {
                // Valid throw
                let velocity = peakZ * 3.5   // calibration factor → m/s
                onThrowDetected?(velocity)
                isReady = false
                stationaryStart = nil
            }
            spikeStart = nil
            peakZ = 0
        }

        lastTimestamp = now
    }

    func reset() {
        spikeStart = nil
        peakZ = 0
        stationaryStart = nil
        isReady = false
    }
}
