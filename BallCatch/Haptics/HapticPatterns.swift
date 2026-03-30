import CoreHaptics
import Foundation

enum HapticPattern {
    // MARK: - Rolling (continuous, updated externally with intensity)
    static func rollingContinuous(intensity: Float) throws -> CHHapticPattern {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: 0.1
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    // MARK: - Wall bounce
    static func wallBounce() throws -> CHHapticPattern {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        return try CHHapticPattern(events: [event], parameters: [])
    }

    // MARK: - Throw release: ascending sweep + cutoff
    static func throwRelease() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        let steps = 8
        for i in 0..<steps {
            let t = Double(i) * 0.012
            let intVal = Float(0.3 + 0.7 * Double(i) / Double(steps))
            let shrp = Float(0.2 + 0.6 * Double(i) / Double(steps))
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intVal)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: shrp)
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: t))
        }
        return try CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - Catch warning (500ms before catch): two taps
    static func catchWarning() throws -> CHHapticPattern {
        let tap = { (t: Double) -> CHHapticEvent in
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            return CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: t)
        }
        let events = [tap(0.0), tap(0.12)]
        return try CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - Perfect catch: deep heavy thud (80ms sustained)
    static func perfectCatch() throws -> CHHapticPattern {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 0.08
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    // MARK: - Miss/fumble: lighter hollow thud
    static func miss() throws -> CHHapticPattern {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 0.05
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }
}
