import Foundation
import Observation
import Core

public struct DashboardSnapshot: Sendable {
    public struct SystemSummary: Identifiable, Sendable {
        public var category: HouseCategory
        public var componentCount: Int
        public var itemCount: Int
        public var id: HouseCategory.ID { category.id }

        public var subtitle: String {
            switch (componentCount, itemCount) {
            case (0, 0): "Nothing documented yet"
            case (_, 0): "\(componentCount) component\(componentCount == 1 ? "" : "s")"
            default: "\(itemCount) item\(itemCount == 1 ? "" : "s")"
            }
        }
    }

    public var houseName: String
    public var systems: [SystemSummary]
    public var quickAccess: [KnowledgeItem]
    public var recentItems: [KnowledgeItem]
    public var frequentInstructions: [Instruction]
    public var totalItems: Int
    public var totalInstructions: Int
    public var tree: CategoryTree

    public var isEmpty: Bool { totalItems == 0 && totalInstructions == 0 }

    /// "Heating › Boiler" for an item's category.
    public func location(of categoryID: HouseCategory.ID?) -> String {
        guard let categoryID else { return "" }
        return tree.breadcrumb(for: categoryID)
    }

    public func category(_ id: HouseCategory.ID?) -> HouseCategory? {
        id.flatMap { tree[$0] }
    }
}

@MainActor
@Observable
public final class DashboardViewModel {
    public enum State {
        case loading
        case loaded(DashboardSnapshot)
        case failed(String)
    }

    public private(set) var state: State = .loading

    private let houseRepository: any HouseRepository
    private let categoryRepository: any CategoryRepository
    private let itemRepository: any KnowledgeItemRepository
    private let instructionRepository: any InstructionRepository

    public init(
        houseRepository: any HouseRepository,
        categoryRepository: any CategoryRepository,
        itemRepository: any KnowledgeItemRepository,
        instructionRepository: any InstructionRepository
    ) {
        self.houseRepository = houseRepository
        self.categoryRepository = categoryRepository
        self.itemRepository = itemRepository
        self.instructionRepository = instructionRepository
    }

    public var title: String {
        if case .loaded(let snapshot) = state { return snapshot.houseName }
        return "Home"
    }

    public func load() async {
        let houses = houseRepository
        let categories = categoryRepository
        let items = itemRepository
        let instructions = instructionRepository

        do {
            async let house = houses.fetchHouse()
            async let allCategories = categories.fetchCategories()
            async let allItems = items.fetchItems(categoryID: nil)
            async let recent = items.fetchRecentItems(limit: 5)
            async let favorites = items.fetchFavoriteItems()
            async let frequent = instructions.fetchFrequentInstructions(limit: 4)
            async let allInstructions = instructions.fetchInstructions(categoryID: nil)

            let tree = CategoryTree(try await allCategories)
            let itemList = try await allItems

            // Count items per top-level system, including items filed under its components.
            var itemsPerSystem: [HouseCategory.ID: Int] = [:]
            for item in itemList {
                if let system = tree.system(containing: item.categoryID) {
                    itemsPerSystem[system.id, default: 0] += 1
                }
            }

            let systems = tree.systems.map { system in
                DashboardSnapshot.SystemSummary(
                    category: system,
                    componentCount: tree.descendants(of: system.id).count,
                    itemCount: itemsPerSystem[system.id] ?? 0
                )
            }

            let snapshot = DashboardSnapshot(
                houseName: try await house.name,
                systems: systems,
                quickAccess: try await favorites,
                recentItems: try await recent,
                frequentInstructions: try await frequent,
                totalItems: itemList.count,
                totalInstructions: try await allInstructions.count,
                tree: tree
            )
            state = .loaded(snapshot)
        } catch is CancellationError {
            // View disappeared mid-load; keep whatever is on screen.
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
