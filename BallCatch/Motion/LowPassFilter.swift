import Foundation

/// Simple first-order IIR low-pass filter.
/// cutoff ~10 Hz at 100 Hz sample rate → α ≈ 0.239
struct LowPassFilter {
    var alpha: Double
    private var x: Double = 0
    private var y: Double = 0
    private var z: Double = 0

    init(cutoffHz: Double = 10.0, sampleHz: Double = 100.0) {
        let rc = 1.0 / (2.0 * Double.pi * cutoffHz)
        let dt = 1.0 / sampleHz
        alpha = dt / (dt + rc)
    }

    mutating func filter(x newX: Double, y newY: Double, z newZ: Double) -> (x: Double, y: Double, z: Double) {
        x = alpha * newX + (1.0 - alpha) * x
        y = alpha * newY + (1.0 - alpha) * y
        z = alpha * newZ + (1.0 - alpha) * z
        return (x, y, z)
    }

    mutating func reset() {
        x = 0; y = 0; z = 0
    }
}
