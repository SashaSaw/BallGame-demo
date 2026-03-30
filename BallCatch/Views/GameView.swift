import SwiftUI
import SpriteKit

struct GameView: View {
    private let motionManager = MotionManager.shared
    private let gameState = GameStateManager.shared
    private let haptics = HapticManager.shared

    @State private var scene: BallScene?
    @State private var throwStats = ThrowDetectorStats()
    // Timer drives stats overlay redraws — BallScene is not @Observable
    @State private var statsRefreshTick: Int = 0

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
                ballPosition: scene?.ballPosition ?? .zero,
                refreshTick: statsRefreshTick
            )
            .allowsHitTesting(false)
        }
        .background(Color(white: 0.08))
        .onAppear { setupScene() }
        // Refresh stats overlay at ~30fps
        .onReceive(Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()) { _ in
            statsRefreshTick &+= 1
        }
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
        // Give the SKView a real frame upfront so the scene has correct
        // dimensions when didMove(to:) fires — without this the scene size
        // is zero and the ball spawns at (0,0).
        let frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)
        let view = SKView(frame: frame)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}
