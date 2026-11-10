import SwiftUI
import Observation
import Core

/// Owns the selected tab and one navigation path per tab, so any part of the app
/// (e.g. a citation in the assistant) can deep-link with a single call.
@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case home, house, procedures, assistant
    }

    var selectedTab: Tab = .home
    var homePath: [AppDestination] = []
    var housePath: [AppDestination] = []
    var proceduresPath: [AppDestination] = []
    var assistantPath: [AppDestination] = []
    var isUploadCenterPresented = false

    /// Pushes a destination onto a tab's stack, switching to that tab first.
    func open(_ destination: AppDestination, in tab: Tab? = nil) {
        let target = tab ?? selectedTab
        selectedTab = target
        switch target {
        case .home: homePath.append(destination)
        case .house: housePath.append(destination)
        case .procedures: proceduresPath.append(destination)
        case .assistant: assistantPath.append(destination)
        }
    }

    func show(_ tab: Tab, popToRoot: Bool = false) {
        selectedTab = tab
        guard popToRoot else { return }
        switch tab {
        case .home: homePath.removeAll()
        case .house: housePath.removeAll()
        case .procedures: proceduresPath.removeAll()
        case .assistant: assistantPath.removeAll()
        }
    }

    func presentUploadCenter() {
        isUploadCenterPresented = true
    }
}
