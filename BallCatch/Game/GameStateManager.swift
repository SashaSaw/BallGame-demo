import Foundation
import Combine

enum BallState: String, Equatable {
    case rolling    = "ROLLING"
    case throwing   = "THROWING"
    case airborne   = "AIRBORNE"
    case landing    = "LANDING"
    case catching   = "CATCHING"
    case dropped    = "DROPPED"
}

@Observable
final class GameStateManager {
    static let shared = GameStateManager()

    private(set) var state: BallState = .rolling

    // Stats
    private(set) var streak: Int = 0
    private(set) var lastThrowVelocity: Double = 0
    private(set) var lastFlightTime: Double = 0

    // Airborne tracking
    private(set) var catchWindowOpen: Bool = false
    private(set) var catchWindowRemaining: Double = 0
    private(set) var airborneProgress: Double = 0   // 0→1 during flight

    private var airborneStartTime: Date?
    private var expectedFlightTime: Double = 0
    private var catchWindowTimer: Timer?
    private var progressTimer: Timer?

    private init() {}

    func transition(to newState: BallState) {
        guard state != newState else { return }
        state = newState

        switch newState {
        case .throwing:
            break
        case .airborne:
            airborneStartTime = Date()
        case .catching:
            break
        case .dropped:
            streak = 0
            endAirborne()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.transition(to: .rolling)
            }
        case .rolling, .landing:
            endAirborne()
        }
    }

    func beginFlight(velocity: Double) {
        let scaledGravity = 5.0   // ~half earth gravity (4.9 m/s²) — slower arc
        let flightTime = 2.0 * velocity / scaledGravity
        lastThrowVelocity = velocity
        lastFlightTime = flightTime
        expectedFlightTime = flightTime
        catchWindowOpen = false
        catchWindowRemaining = 0
        airborneProgress = 0

        transition(to: .airborne)

        // Open catch window at 80% of flight time (±20%)
        let windowOpenAt = flightTime * 0.8
        let windowDuration = flightTime * 0.4   // 80%–120% → 40% of flight

        DispatchQueue.main.asyncAfter(deadline: .now() + windowOpenAt) { [weak self] in
            guard let self, self.state == .airborne else { return }
            self.catchWindowOpen = true
            self.catchWindowRemaining = windowDuration

            self.catchWindowTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
                guard let self else { t.invalidate(); return }
                self.catchWindowRemaining = max(0, self.catchWindowRemaining - 0.05)
                if self.catchWindowRemaining <= 0 {
                    t.invalidate()
                    if self.state == .airborne {
                        self.miss()
                    }
                }
            }
        }

        // Progress updater
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] t in
            guard let self, let start = self.airborneStartTime, self.state == .airborne else {
                t.invalidate(); return
            }
            self.airborneProgress = min(1.0, Date().timeIntervalSince(start) / self.expectedFlightTime)
        }
    }

    func registerCatch() {
        guard state == .airborne, catchWindowOpen else { return }
        catchWindowTimer?.invalidate()
        progressTimer?.invalidate()
        catchWindowOpen = false
        streak += 1
        transition(to: .catching)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.transition(to: .rolling)
        }
    }

    func miss() {
        catchWindowTimer?.invalidate()
        progressTimer?.invalidate()
        catchWindowOpen = false
        streak = 0
        transition(to: .dropped)
    }

    private func endAirborne() {
        catchWindowTimer?.invalidate()
        progressTimer?.invalidate()
        catchWindowOpen = false
        catchWindowRemaining = 0
        airborneStartTime = nil
    }
}
