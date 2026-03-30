import SwiftUI

struct StatsOverlayView: View {
    let motionManager: MotionManager
    let gameState: GameStateManager
    let throwDetector: ThrowDetectorStats
    let ballVelocity: CGVector
    let ballPosition: CGPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            statLine("STATE", gameState.state.rawValue, color: stateColor)
            statLine("STREAK", "\(gameState.streak)")
            Divider().background(Color.white.opacity(0.3)).padding(.vertical, 1)

            statLine("BALL VEL", String(format: "%.1f px/s", ballVelocity.magnitude))
            statLine("BALL POS", String(format: "(%.0f, %.0f)", ballPosition.x, ballPosition.y))
            Divider().background(Color.white.opacity(0.3)).padding(.vertical, 1)

            statLine("GRAV X/Y/Z", String(format: "%.3f / %.3f / %.3f",
                                          motionManager.gravityX,
                                          motionManager.gravityY,
                                          motionManager.gravityZ))
            statLine("ACC X/Y/Z", String(format: "%.3f / %.3f / %.3f",
                                         motionManager.userAccX,
                                         motionManager.userAccY,
                                         motionManager.userAccZ))
            statLine("PITCH/ROLL/YAW", String(format: "%.1f° / %.1f° / %.1f°",
                                               motionManager.pitch * 180 / .pi,
                                               motionManager.roll * 180 / .pi,
                                               motionManager.yaw * 180 / .pi))
            statLine("ROT X/Y/Z", String(format: "%.2f / %.2f / %.2f",
                                         motionManager.rotX,
                                         motionManager.rotY,
                                         motionManager.rotZ))
            Divider().background(Color.white.opacity(0.3)).padding(.vertical, 1)

            statLine("THROW Z", String(format: "%.3f g / 1.800 g",
                                       throwDetector.currentZAcceleration),
                     color: throwDetector.currentZAcceleration > 1.8 ? .yellow : .white)
            statLine("THROW READY", throwDetector.isReady ? "YES" : "NO",
                     color: throwDetector.isReady ? .green : .white)
            Divider().background(Color.white.opacity(0.3)).padding(.vertical, 1)

            statLine("CATCH WIN", gameState.catchWindowOpen ? "OPEN" : "CLOSED",
                     color: gameState.catchWindowOpen ? .green : .white)
            if gameState.catchWindowOpen {
                statLine("WIN REMAIN", String(format: "%.2fs", gameState.catchWindowRemaining),
                         color: .green)
            }
            statLine("LAST VEL", String(format: "%.2f m/s", gameState.lastThrowVelocity))
            statLine("LAST FLIGHT", String(format: "%.2fs", gameState.lastFlightTime))
            Divider().background(Color.white.opacity(0.3)).padding(.vertical, 1)
            statLine("UPDATE HZ", String(format: "%.0f Hz", motionManager.updateHz))
        }
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .foregroundColor(.white)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.55))
        )
        .padding(.top, 50)
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var stateColor: Color {
        switch gameState.state {
        case .rolling:   return .white
        case .throwing:  return .orange
        case .airborne:  return .cyan
        case .landing:   return .yellow
        case .catching:  return .green
        case .dropped:   return .red
        }
    }

    @ViewBuilder
    private func statLine(_ label: String, _ value: String, color: Color = .white) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 88, alignment: .leading)
            Text(value)
                .foregroundColor(color)
        }
    }
}

/// Thin wrapper so StatsOverlayView can read ThrowDetector state without making ThrowDetector @Observable
@Observable
final class ThrowDetectorStats {
    var currentZAcceleration: Double = 0
    var isReady: Bool = false
}
