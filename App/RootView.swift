import SwiftUI
import Core
import Dashboard
import KnowledgeBase
import Instructions
import AIChat

struct RootView: View {
    let container: AppContainer
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                DashboardView(
                    viewModel: container.makeDashboardViewModel(),
                    onAskAssistant: { router.show(.assistant) },
                    onAddContent: { router.presentUploadCenter() },
                    onShowAllInstructions: { router.show(.procedures, popToRoot: true) }
                )
                .withAppDestinations(container)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppRouter.Tab.home)

            NavigationStack(path: $router.housePath) {
                HouseBrowserView(
                    viewModel: container.makeHouseBrowserViewModel(),
                    onAddContent: { router.presentUploadCenter() }
                )
                .withAppDestinations(container)
            }
            .tabItem { Label("House", systemImage: "square.grid.2x2") }
            .tag(AppRouter.Tab.house)

            NavigationStack(path: $router.proceduresPath) {
                InstructionsLibraryView(viewModel: container.makeInstructionsLibraryViewModel())
                    .withAppDestinations(container)
            }
            .tabItem { Label("Procedures", systemImage: "list.number") }
            .tag(AppRouter.Tab.procedures)

            NavigationStack(path: $router.assistantPath) {
                AssistantHomeView()
                    .withAppDestinations(container)
            }
            .tabItem { Label("Assistant", systemImage: "sparkles") }
            .tag(AppRouter.Tab.assistant)
        }
        .sheet(isPresented: $router.isUploadCenterPresented) {
            UploadCenterView()
        }
    }
}

// MARK: - Destination resolution

private struct AppDestinationModifier: ViewModifier {
    let container: AppContainer

    func body(content: Content) -> some View {
        content.navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .category(let id):
                CategoryDetailView(viewModel: container.makeCategoryDetailViewModel(id: id))
            case .knowledgeItem(let id):
                KnowledgeItemDetailView(viewModel: container.makeKnowledgeItemDetailViewModel(id: id))
            case .instruction(let id):
                InstructionDetailView(viewModel: container.makeInstructionDetailViewModel(id: id))
            }
        }
    }
}

private extension View {
    /// Registers the app-wide destination resolver on a navigation stack's root.
    func withAppDestinations(_ container: AppContainer) -> some View {
        modifier(AppDestinationModifier(container: container))
    }
}

#Preview {
    RootView(container: .preview(), router: AppRouter())
}
