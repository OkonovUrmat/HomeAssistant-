import SwiftUI
import Observation
import Core
import DesignSystem

@MainActor
@Observable
public final class CategoryDetailViewModel {
    public struct Content {
        public var category: HouseCategory
        public var breadcrumb: String
        public var hazard: HazardLevel
        public var components: [HouseCategory]
        public var items: [KnowledgeItem]
        public var instructions: [Instruction]

        public var isEmpty: Bool { components.isEmpty && items.isEmpty && instructions.isEmpty }
    }

    public enum State {
        case loading
        case loaded(Content)
        case notFound
        case failed(String)
    }

    public private(set) var state: State = .loading

    private let categoryID: HouseCategory.ID
    private let categoryRepository: any CategoryRepository
    private let itemRepository: any KnowledgeItemRepository
    private let instructionRepository: any InstructionRepository

    public init(
        categoryID: HouseCategory.ID,
        categoryRepository: any CategoryRepository,
        itemRepository: any KnowledgeItemRepository,
        instructionRepository: any InstructionRepository
    ) {
        self.categoryID = categoryID
        self.categoryRepository = categoryRepository
        self.itemRepository = itemRepository
        self.instructionRepository = instructionRepository
    }

    public var title: String {
        if case .loaded(let content) = state { return content.category.name }
        return ""
    }

    public func load() async {
        let categories = categoryRepository
        let items = itemRepository
        let instructions = instructionRepository
        let id = categoryID

        do {
            async let allCategories = categories.fetchCategories()
            async let categoryItems = items.fetchItems(categoryID: id)
            async let categoryInstructions = instructions.fetchInstructions(categoryID: id)

            let tree = CategoryTree(try await allCategories)
            guard let category = tree[id] else {
                state = .notFound
                return
            }
            let path = tree.path(to: id)
            state = .loaded(Content(
                category: category,
                breadcrumb: path.dropLast().map(\.name).joined(separator: " › "),
                hazard: tree.effectiveHazard(of: id),
                components: tree.children(of: id),
                items: try await categoryItems,
                instructions: try await categoryInstructions
            ))
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

/// A system or component: its hazard banner, sub-components, knowledge and procedures.
public struct CategoryDetailView: View {
    @State private var viewModel: CategoryDetailViewModel

    public init(viewModel: CategoryDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .notFound:
                ContentUnavailableView("Not Found", systemImage: "questionmark.folder", description: Text("This category may have been deleted."))
            case .failed(let message):
                ContentUnavailableView("Couldn't Load", systemImage: "exclamationmark.triangle", description: Text(message))
            case .loaded(let content):
                list(content)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }

    private func list(_ content: CategoryDetailViewModel.Content) -> some View {
        List {
            if !content.breadcrumb.isEmpty || content.hazard != .normal {
                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        if !content.breadcrumb.isEmpty {
                            Text(content.breadcrumb)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if content.hazard != .normal {
                            HazardBanner(content.hazard)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }

            if !content.components.isEmpty {
                Section("Components") {
                    ForEach(content.components) { component in
                        NavigationLink(value: AppDestination.category(component.id)) {
                            DSRow(symbolName: component.symbolName, tint: component.tint.color, title: component.name)
                        }
                    }
                }
            }

            if !content.instructions.isEmpty {
                Section("Procedures") {
                    ForEach(content.instructions) { instruction in
                        NavigationLink(value: AppDestination.instruction(instruction.id)) {
                            DSRow(
                                symbolName: "list.number",
                                tint: content.category.tint.color,
                                title: instruction.title,
                                subtitle: "\(instruction.steps.count) steps"
                            )
                        }
                    }
                }
            }

            if !content.items.isEmpty {
                Section("Knowledge") {
                    ForEach(content.items) { item in
                        NavigationLink(value: AppDestination.knowledgeItem(item.id)) {
                            DSRow(
                                symbolName: item.coverAttachment?.kind.symbolName ?? "doc.text",
                                tint: content.category.tint.color,
                                title: item.title,
                                subtitle: item.details
                            )
                        }
                    }
                }
            }

            if content.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Nothing Documented Yet",
                        systemImage: content.category.symbolName,
                        description: Text("Add photos, manuals, notes or procedures for \(content.category.name).")
                    )
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.load() }
    }
}
