import SwiftUI
import SpriteKit

struct GameView: View {
    private let motionManager = MotionManager.shared
    private let gameState = GameStateManager.shared
    private let haptics = HapticManager.shared

    @State private var scene: BallScene?
    @State private var throwStats = ThrowDetectorStats()

    // Desaturation while airborne
    private var saturation: Double { gameState.state == .airborne ? 0.3 : 1.0 }

    var body: some View {
        ZStack {
            // SpriteKit scene
            if let scene {
                SpriteKitView(scene: scene)
                    .ignoresSafeArea()
                    .saturation(saturation)
                    .animation(.easeInOut(duration: 0.4), value: saturation)
            }

            // Airborne shadow at bottom center
            if gameState.state == .airborne {
                VStack {
                    Spacer()
                    ShadowView(
                        progress: gameState.airborneProgress,
                        isVisible: gameState.state == .airborne
                    )
                    .padding(.bottom, 80)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Debug stats overlay (always visible)
            StatsOverlayView(
                motionManager: motionManager,
                gameState: gameState,
                throwDetector: throwStats,
                ballVelocity: scene?.ballVelocity ?? .zero,
                ballPosition: scene?.ballPosition ?? .zero
            )
            .allowsHitTesting(false)
        }
        .background(Color(white: 0.08))
        .onAppear { setupScene() }
    }

    private func setupScene() {
        let s = BallScene()
        s.size = UIScreen.main.bounds.size
        s.scaleMode = .resizeFill
        s.onThrowStatsUpdate = { z, ready in
            throwStats.currentZAcceleration = z
            throwStats.isReady = ready
        }
        scene = s
    }
}

/// SwiftUI wrapper for SKView
struct SpriteKitView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}
