import CoreMotion
import Combine
import Foundation

@Observable
final class MotionManager {
    static let shared = MotionManager()

    // Raw gravity (filtered)
    private(set) var gravityX: Double = 0
    private(set) var gravityY: Double = 0
    private(set) var gravityZ: Double = -1

    // Raw user acceleration
    private(set) var userAccX: Double = 0
    private(set) var userAccY: Double = 0
    private(set) var userAccZ: Double = 0

    // Attitude
    private(set) var pitch: Double = 0
    private(set) var roll: Double = 0
    private(set) var yaw: Double = 0

    // Rotation rate
    private(set) var rotX: Double = 0
    private(set) var rotY: Double = 0
    private(set) var rotZ: Double = 0

    // Frequency measurement
    private(set) var updateHz: Double = 0

    private let manager = CMMotionManager()
    private var filter = LowPassFilter(cutoffHz: 10.0, sampleHz: 100.0)
    private let queue = OperationQueue()

    private var lastTimestamp: TimeInterval = 0
    private var frameCount = 0
    private var hzTimer: TimeInterval = 0

    // Callbacks
    var onMotionUpdate: ((CMDeviceMotion) -> Void)?

    private init() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.01  // 100 Hz
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.process(motion: motion)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    private func process(motion: CMDeviceMotion) {
        let g = filter.filter(
            x: motion.gravity.x,
            y: motion.gravity.y,
            z: motion.gravity.z
        )

        let now = motion.timestamp
        frameCount += 1
        if now - hzTimer >= 1.0 {
            let hz = Double(frameCount) / (now - hzTimer)
            hzTimer = now
            frameCount = 0
            DispatchQueue.main.async { self.updateHz = hz }
        }

        DispatchQueue.main.async {
            self.gravityX = g.x
            self.gravityY = g.y
            self.gravityZ = g.z
            self.userAccX = motion.userAcceleration.x
            self.userAccY = motion.userAcceleration.y
            self.userAccZ = motion.userAcceleration.z
            self.pitch = motion.attitude.pitch
            self.roll = motion.attitude.roll
            self.yaw = motion.attitude.yaw
            self.rotX = motion.rotationRate.x
            self.rotY = motion.rotationRate.y
            self.rotZ = motion.rotationRate.z
        }

        onMotionUpdate?(motion)
    }
}
