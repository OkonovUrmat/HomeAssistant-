import SwiftUI
import Observation
import Core
import DesignSystem

@MainActor
@Observable
public final class HouseBrowserViewModel {
    public private(set) var tree: CategoryTree?
    public private(set) var errorMessage: String?

    private let categoryRepository: any CategoryRepository

    public init(categoryRepository: any CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public func load() async {
        do {
            tree = CategoryTree(try await categoryRepository.fetchCategories())
            errorMessage = nil
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// The "House" tab: every system with its components.
public struct HouseBrowserView: View {
    @State private var viewModel: HouseBrowserViewModel
    private let onAddContent: () -> Void

    public init(viewModel: HouseBrowserViewModel, onAddContent: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onAddContent = onAddContent
    }

    public var body: some View {
        Group {
            if let tree = viewModel.tree {
                if tree.systems.isEmpty {
                    ContentUnavailableView(
                        "No Systems Yet",
                        systemImage: "house",
                        description: Text("Add your first house system, like Heating or Water Supply.")
                    )
                } else {
                    list(tree)
                }
            } else if let message = viewModel.errorMessage {
                ContentUnavailableView("Couldn't Load", systemImage: "exclamationmark.triangle", description: Text(message))
            } else {
                ProgressView()
            }
        }
        .navigationTitle("House")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAddContent) { Image(systemName: "plus") }
                    .accessibilityLabel("Add to knowledge base")
            }
        }
        .task { await viewModel.load() }
    }

    private func list(_ tree: CategoryTree) -> some View {
        List {
            ForEach(tree.systems) { system in
                Section {
                    NavigationLink(value: AppDestination.category(system.id)) {
                        DSRow(
                            symbolName: system.symbolName,
                            tint: system.tint.color,
                            title: system.name,
                            subtitle: system.hazard == .normal ? nil : system.hazard.title
                        )
                    }
                    ForEach(tree.children(of: system.id)) { component in
                        NavigationLink(value: AppDestination.category(component.id)) {
                            Label {
                                Text(component.name)
                            } icon: {
                                Image(systemName: component.symbolName)
                                    .foregroundStyle(component.tint.color)
                            }
                        }
                        .padding(.leading, DS.Spacing.l)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.load() }
    }
}
