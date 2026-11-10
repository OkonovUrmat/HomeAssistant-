import SwiftUI

@main
@MainActor
struct HomeAssistantApp: App {
    @State private var container = AppContainer.live()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView(container: container, router: router)
        }
    }
}
