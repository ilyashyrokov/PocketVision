import SwiftUI

@main
struct PocketVisionApp: App {
    @StateObject private var model = PocketVisionModel()

    var body: some Scene {
        WindowGroup {
            PocketVisionRootView()
                .environmentObject(model)
                .preferredColorScheme(.light)
        }
    }
}
