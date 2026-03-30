import SpriteKit
import CoreMotion
import Foundation

final class BallScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Nodes
    private var ball: BallNode!
    private var walls: [SKNode] = []
    private var platformNode: SKShapeNode?

    // MARK: - External references
    private let motionManager = MotionManager.shared
    private let gameState = GameStateManager.shared
    private let haptics = HapticManager.shared
    private let throwDetector = ThrowDetector()
    private let catchDetector = CatchDetector()

    // MARK: - State
    private var lastUpdateTime: TimeInterval = 0
    private var isAirborne: Bool = false

    // MARK: - Stats (read by StatsOverlayView)
    var ballVelocity: CGVector = .zero
    var ballPosition: CGPoint = .zero

    // Callback to forward ThrowDetector stats to SwiftUI
    var onThrowStatsUpdate: ((Double, Bool) -> Void)?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(white: 0.08, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        setupWalls()
        ball = BallNode(in: self)
        addChild(ball)
        setupPlatform()

        setupDetectors()
        motionManager.start()
    }

    private func setupWalls() {
        let wallThickness: CGFloat = 20
        let w = size.width
        let h = size.height

        let wallDefs: [(CGRect, String)] = [
            (CGRect(x: -wallThickness, y: 0, width: wallThickness, height: h), "left"),
            (CGRect(x: w, y: 0, width: wallThickness, height: h), "right"),
            (CGRect(x: 0, y: -wallThickness, width: w, height: wallThickness), "bottom"),
            (CGRect(x: 0, y: h, width: w, height: wallThickness), "top")
        ]

        for (rect, name) in wallDefs {
            let node = SKNode()
            node.name = name
            node.physicsBody = SKPhysicsBody(rectangleOf: rect.size,
                                              center: CGPoint(x: rect.midX, y: rect.midY))
            node.physicsBody?.isDynamic = false
            node.physicsBody?.restitution = 0.4
            node.physicsBody?.friction = 0.1
            node.physicsBody?.categoryBitMask = BallNode.wallCategoryBitmask
            node.physicsBody?.collisionBitMask = BallNode.categoryBitmask
            node.physicsBody?.contactTestBitMask = BallNode.categoryBitmask
            addChild(node)
            walls.append(node)
        }
    }

    private func setupPlatform() {
        // A subtle rounded-rect representing the phone screen surface
        let w = size.width * 0.55
        let h = size.height * 0.28
        let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
        let node = SKShapeNode(rect: rect, cornerRadius: 22)
        node.strokeColor = UIColor.white.withAlphaComponent(0.18)
        node.fillColor   = UIColor.white.withAlphaComponent(0.04)
        node.lineWidth   = 1.5
        node.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        node.zPosition   = 5
        node.alpha        = 0
        addChild(node)
        platformNode = node
    }

    private func setupDetectors() {
        throwDetector.onThrowDetected = { [weak self] velocity in
            guard let self, self.gameState.state == .rolling else { return }
            self.haptics.stopRolling()
            self.haptics.playThrowRelease()
            self.gameState.transition(to: .throwing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.gameState.beginFlight(velocity: velocity)
                self.ball.setAirborne(true)
                self.isAirborne = true
                self.ball.physicsBody?.isDynamic = false
            }
        }

        catchDetector.onPreTrigger = { [weak self] in
            self?.haptics.playCatchWarning()
        }

        catchDetector.onCatchDetected = { [weak self] in
            guard let self else { return }
            self.gameState.registerCatch()
            self.haptics.playPerfectCatch()
            self.ball.setAirborne(false)
            self.isAirborne = false
            self.ball.physicsBody?.isDynamic = true
            self.ball.physicsBody?.velocity = .zero
        }

        motionManager.onMotionUpdate = { [weak self] motion in
            guard let self else { return }
            self.throwDetector.process(motion: motion)
            // Forward stats to SwiftUI overlay
            let z = self.throwDetector.currentZAcceleration
            let ready = self.throwDetector.isReady
            DispatchQueue.main.async { self.onThrowStatsUpdate?(z, ready) }
            self.catchDetector.isWindowOpen = self.gameState.catchWindowOpen
            self.catchDetector.process(motion: motion)

            // Miss: dropped state cleanup
            if self.gameState.state == .dropped {
                self.isAirborne = false
                DispatchQueue.main.async {
                    self.ball.setAirborne(false)
                    self.ball.physicsBody?.isDynamic = true
                    self.ball.physicsBody?.velocity = .zero
                    self.haptics.playMiss()
                }
            }
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if isAirborne {
            // Drive perspective scaling every frame during flight
            let progress = gameState.airborneProgress
            ball.updateAirborneScale(progress: progress)

            // Platform: fades in, shrinks away as ball rises, returns on landing
            let p = CGFloat(progress)
            let normalizedHeight = 4.0 * p * (1.0 - p)  // 0→1→0
            let D: CGFloat = 1.5
            let platformScale = D / (D + normalizedHeight * 1.0)  // recedes
            platformNode?.setScale(platformScale)
            platformNode?.alpha = CGFloat(0.6 + 0.4 * (1.0 - normalizedHeight))
            return
        }

        // Hide platform when rolling
        platformNode?.alpha = 0

        // Apply gravity from device motion
        let gx = motionManager.gravityX
        let gy = motionManager.gravityY
        let scale: CGFloat = 120.0   // reduced from 300 — gentler rolling
        physicsWorld.gravity = CGVector(dx: CGFloat(gx) * scale, dy: CGFloat(gy) * scale)

        // Update stats
        ballVelocity = ball.physicsBody?.velocity ?? .zero
        ballPosition = ball.position

        // Micro-motion
        ball.updateStillness(dt: dt, currentTime: currentTime)

        // Rolling haptics
        let speed = (ball.physicsBody?.velocity ?? .zero).magnitude
        let maxSpeed: CGFloat = 600
        let intensity = Float(min(speed / maxSpeed, 1.0)) * 0.4
        haptics.updateRollingIntensity(intensity)
    }

    // MARK: - Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        let isBallContact = (nodeA == ball || nodeB == ball)
        guard isBallContact else { return }

        let normal = contact.contactNormal
        ball.squashOnBounce(normal: normal)
        haptics.playWallBounce()
    }

    // MARK: - Scene resize

    override func didChangeSize(_ oldSize: CGSize) {
        walls.forEach { $0.removeFromParent() }
        walls.removeAll()
        setupWalls()
        // If the scene was resized from zero (layout pass after first present),
        // reposition the ball and platform to centre.
        if let ball, (oldSize.width < 10 || ball.position == .zero) {
            ball.position = CGPoint(x: size.width / 2, y: size.height / 2)
            ball.physicsBody?.velocity = .zero
        }
        platformNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
}
