import CoreMotion
import Foundation

/// Detects a catch gesture: downward z-acceleration snap while phone is near level.
final class CatchDetector {
    let catchThreshold: Double = -0.8       // g (downward)
    let levelAngleLimit: Double = 30.0      // degrees from level

    var onCatchDetected: (() -> Void)?
    var isWindowOpen: Bool = false           // set by GameStateManager

    // Pre-trigger: fire haptic 8ms before expected catch
    var onPreTrigger: (() -> Void)?
    private var preTriggerFired = false

    func process(motion: CMDeviceMotion) {
        guard isWindowOpen else {
            preTriggerFired = false
            return
        }

        let z = motion.userAcceleration.z
        let pitch = motion.attitude.pitch * (180 / Double.pi)
        let phoneLevel = abs(pitch) < levelAngleLimit

        // Pre-trigger 8ms early is handled externally via timing;
        // here we fire haptic on first eligible frame
        if z < catchThreshold && phoneLevel {
            if !preTriggerFired {
                preTriggerFired = true
                onPreTrigger?()
            }
            onCatchDetected?()
        }
    }

    func reset() {
        preTriggerFired = false
    }
}
