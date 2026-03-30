import CoreMotion
import Foundation

/// Detects a catch gesture: downward z-acceleration snap while catch window is open.
final class CatchDetector {
    var catchThreshold: Double = -0.6       // g (downward) — slightly easier than -0.8

    var onCatchDetected: (() -> Void)?
    var isWindowOpen: Bool = false

    var onPreTrigger: (() -> Void)?
    private var preTriggerFired = false
    private var catchFired = false          // only fire once per window

    func process(motion: CMDeviceMotion) {
        guard isWindowOpen else {
            preTriggerFired = false
            catchFired = false
            return
        }

        let z = motion.userAcceleration.z

        // Pre-trigger haptic on first eligible frame
        if z < catchThreshold && !preTriggerFired {
            preTriggerFired = true
            onPreTrigger?()
        }

        if z < catchThreshold && !catchFired {
            catchFired = true
            onCatchDetected?()
        }
    }

    func reset() {
        preTriggerFired = false
        catchFired = false
    }
}
