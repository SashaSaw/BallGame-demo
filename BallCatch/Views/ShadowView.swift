import SwiftUI

/// Airborne shadow: grows from small to large as ball approaches, with blur that sharpens.
struct ShadowView: View {
    /// 0 = just thrown (small, blurry), 1 = about to land (large, sharp)
    let progress: Double
    let isVisible: Bool

    private var size: CGFloat { CGFloat(40 + progress * 120) }
    private var blur: Double { 20 - progress * 18 }
    private var opacity: Double { isVisible ? 0.15 + progress * 0.35 : 0 }

    var body: some View {
        Ellipse()
            .fill(Color.black)
            .frame(width: size, height: size * 0.35)
            .blur(radius: blur)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.1), value: progress)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}
