import SwiftUI

@main
struct BallCatchApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .statusBarHidden(true)
        }
    }
}
