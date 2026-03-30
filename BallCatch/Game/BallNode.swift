import SpriteKit
import Foundation

final class BallNode: SKShapeNode {
    static let radius: CGFloat = 44
    static let categoryBitmask: UInt32 = 0x1
    static let wallCategoryBitmask: UInt32 = 0x2

    // Track stillness for micro-motion
    private var stillnessDuration: TimeInterval = 0
    private var lastVelocityMagnitude: CGFloat = 0
    private var lastCheckTime: TimeInterval = 0

    private var isSquashing = false

    init(in scene: SKScene) {
        super.init()
        let r = BallNode.radius
        path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r*2, height: r*2), transform: nil)
        fillColor = .white
        strokeColor = UIColor.white.withAlphaComponent(0.3)
        lineWidth = 1.5

        // Gradient-style shading via radial overlay
        let shine = SKShapeNode(ellipseOf: CGSize(width: r * 0.7, height: r * 0.5))
        shine.fillColor = UIColor.white.withAlphaComponent(0.4)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -r * 0.2, y: r * 0.3)
        shine.zPosition = 1
        addChild(shine)

        // Shadow underneath (subtle)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: r * 1.6, height: r * 0.5))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -(r + 8))
        shadow.zPosition = -1
        addChild(shadow)

        // Physics
        physicsBody = makePhysicsBody(radius: r)
        position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func makePhysicsBody(radius: CGFloat) -> SKPhysicsBody {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.restitution = 0.55
        body.friction = 0.35
        body.linearDamping = 0.2
        body.angularDamping = 0.3
        body.mass = 0.2
        body.categoryBitMask = BallNode.categoryBitmask
        body.collisionBitMask = BallNode.wallCategoryBitmask
        body.contactTestBitMask = BallNode.wallCategoryBitmask
        body.allowsRotation = true
        return body
    }

    // MARK: - Squash & Stretch

    func squashOnBounce(normal: CGVector) {
        guard !isSquashing else { return }
        isSquashing = true

        let squashX: CGFloat = normal.dx != 0 ? 0.65 : 1.0
        let squashY: CGFloat = normal.dy != 0 ? 0.65 : 1.0
        let stretchX: CGFloat = normal.dx != 0 ? 1.0 : 1.25
        let stretchY: CGFloat = normal.dy != 0 ? 1.25 : 1.0

        let squash = SKAction.scaleX(to: squashX, y: squashY, duration: 0.04)
        let stretch = SKAction.scaleX(to: stretchX, y: stretchY, duration: 0.06)
        let restore = SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.08)
        let seq = SKAction.sequence([squash, stretch, restore])

        run(seq) { self.isSquashing = false }
    }

    // MARK: - Micro-motion (alive when still)

    func updateStillness(dt: TimeInterval, currentTime: TimeInterval) {
        guard let body = physicsBody else { return }
        let speed = body.velocity.magnitude
        if speed < 10 {
            stillnessDuration += dt
        } else {
            stillnessDuration = 0
        }

        if stillnessDuration > 5.0 {
            // Add tiny random impulse to keep ball "alive"
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let force = CGVector(dx: cos(angle) * 30, dy: sin(angle) * 30)
            body.applyImpulse(force)
        }
    }

    // MARK: - Airborne appearance

    func setAirborne(_ airborne: Bool) {
        removeAction(forKey: "airborneRestore")
        if !airborne {
            // Return to normal — short snap back
            let grow = SKAction.scale(to: 1.0, duration: 0.15)
            let unfade = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
            run(SKAction.group([grow, unfade]), withKey: "airborneRestore")
        }
    }

    /// Call every frame during flight. progress 0→1 over full arc.
    /// Uses perspective projection: ball comes "out of" the screen toward viewer.
    /// D = focal distance (1.5). Height follows parabola: h = 4p(1-p).
    func updateAirborneScale(progress: Double) {
        let p = CGFloat(progress)
        let normalizedHeight = 4.0 * p * (1.0 - p)   // 0→1→0 parabolic

        let D: CGFloat = 1.5
        // Ball comes toward viewer → gets bigger
        let ballScale = D / max(0.1, D - normalizedHeight * 1.0)
        // Subtle fade at peak to sell depth
        let fadeAlpha = 0.7 + 0.3 * (1.0 - normalizedHeight)

        setScale(ballScale)
        self.alpha = fadeAlpha
    }
}

extension CGVector {
    var magnitude: CGFloat { sqrt(dx*dx + dy*dy) }
}
