import Foundation
import Core

/// Phase 1 storage: a thread-safe in-memory store implementing every repository protocol.
/// Used for previews and tests permanently; replaced by SwiftData for the app in Phase 2.
public actor InMemoryStore {
    private var house: House
    private var categories: [HouseCategory.ID: HouseCategory]
    private var items: [KnowledgeItem.ID: KnowledgeItem]
    private var instructions: [Instruction.ID: Instruction]

    public init(
        house: House,
        categories: [HouseCategory] = [],
        items: [KnowledgeItem] = [],
        instructions: [Instruction] = []
    ) {
        self.house = house
        self.categories = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        self.items = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        self.instructions = Dictionary(uniqueKeysWithValues: instructions.map { ($0.id, $0) })
    }

    /// A store seeded with a house template and, optionally, demo content.
    public static func seeded(with template: HouseTemplate = .standard, includeSampleContent: Bool = false) -> InMemoryStore {
        let categories = template.makeCategories()
        let house = House(name: template.houseName)
        guard includeSampleContent else {
            return InMemoryStore(house: house, categories: categories)
        }
        let sample = SampleContent.make(for: categories)
        return InMemoryStore(house: house, categories: categories, items: sample.items, instructions: sample.instructions)
    }
}

// MARK: - HouseRepository

extension InMemoryStore: HouseRepository {
    public func fetchHouse() async throws -> House { house }

    public func saveHouse(_ house: House) async throws { self.house = house }
}

// MARK: - CategoryRepository

extension InMemoryStore: CategoryRepository {
    public func fetchCategories() async throws -> [HouseCategory] {
        categories.values.sorted(by: CategoryTree.displayOrder)
    }

    public func fetchCategory(id: HouseCategory.ID) async throws -> HouseCategory? {
        categories[id]
    }

    public func saveCategory(_ category: HouseCategory) async throws {
        var category = category
        category.updatedAt = .now
        categories[category.id] = category
    }

    public func deleteCategory(id: HouseCategory.ID) async throws {
        guard categories[id] != nil else { throw RepositoryError.notFound }
        let tree = CategoryTree(Array(categories.values))
        let doomed = Set([id] + tree.descendants(of: id).map(\.id))

        for categoryID in doomed { categories[categoryID] = nil }
        items = items.filter { !doomed.contains($0.value.categoryID) }
        instructions = instructions.filter { entry in
            guard let categoryID = entry.value.categoryID else { return true }
            return !doomed.contains(categoryID)
        }
    }
}

// MARK: - KnowledgeItemRepository

extension InMemoryStore: KnowledgeItemRepository {
    public func fetchItems(categoryID: HouseCategory.ID?) async throws -> [KnowledgeItem] {
        items.values
            .filter { categoryID == nil || $0.categoryID == categoryID }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func fetchRecentItems(limit: Int) async throws -> [KnowledgeItem] {
        Array(items.values.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    public func fetchFavoriteItems() async throws -> [KnowledgeItem] {
        items.values
            .filter(\.isFavorite)
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public func fetchItem(id: KnowledgeItem.ID) async throws -> KnowledgeItem? {
        items[id]
    }

    public func saveItem(_ item: KnowledgeItem) async throws {
        var item = item
        item.updatedAt = .now
        items[item.id] = item
    }

    public func deleteItem(id: KnowledgeItem.ID) async throws {
        guard items.removeValue(forKey: id) != nil else { throw RepositoryError.notFound }
    }
}

// MARK: - InstructionRepository

extension InMemoryStore: InstructionRepository {
    public func fetchInstructions(categoryID: HouseCategory.ID?) async throws -> [Instruction] {
        instructions.values
            .filter { categoryID == nil || $0.categoryID == categoryID }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public func fetchFrequentInstructions(limit: Int) async throws -> [Instruction] {
        let sorted = instructions.values.sorted { lhs, rhs in
            if lhs.usageCount != rhs.usageCount { return lhs.usageCount > rhs.usageCount }
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
        return Array(sorted.prefix(limit))
    }

    public func fetchInstruction(id: Instruction.ID) async throws -> Instruction? {
        instructions[id]
    }

    public func saveInstruction(_ instruction: Instruction) async throws {
        var instruction = instruction
        instruction.updatedAt = .now
        instructions[instruction.id] = instruction
    }

    public func deleteInstruction(id: Instruction.ID) async throws {
        guard instructions.removeValue(forKey: id) != nil else { throw RepositoryError.notFound }
    }

    public func recordInstructionUsage(id: Instruction.ID) async throws {
        guard var instruction = instructions[id] else { throw RepositoryError.notFound }
        instruction.usageCount += 1
        instruction.lastUsedAt = .now
        instructions[id] = instruction
    }
}
