import Foundation

// Repository protocols are the only way features read or write data.
// Phase 1 is backed by an in-memory store; Phase 2 swaps in SwiftData without touching features.

public protocol HouseRepository: Sendable {
    func fetchHouse() async throws -> House
    func saveHouse(_ house: House) async throws
}

public protocol CategoryRepository: Sendable {
    func fetchCategories() async throws -> [HouseCategory]
    func fetchCategory(id: HouseCategory.ID) async throws -> HouseCategory?
    func saveCategory(_ category: HouseCategory) async throws
    /// Deletes the category, its whole subtree, and every item and instruction filed under it.
    func deleteCategory(id: HouseCategory.ID) async throws
}

public protocol KnowledgeItemRepository: Sendable {
    /// Items filed directly under `categoryID`, or all items when `nil`. Newest first.
    func fetchItems(categoryID: HouseCategory.ID?) async throws -> [KnowledgeItem]
    func fetchRecentItems(limit: Int) async throws -> [KnowledgeItem]
    func fetchFavoriteItems() async throws -> [KnowledgeItem]
    func fetchItem(id: KnowledgeItem.ID) async throws -> KnowledgeItem?
    func saveItem(_ item: KnowledgeItem) async throws
    func deleteItem(id: KnowledgeItem.ID) async throws
}

public protocol InstructionRepository: Sendable {
    /// Instructions filed under `categoryID`, or all instructions when `nil`. Alphabetical.
    func fetchInstructions(categoryID: HouseCategory.ID?) async throws -> [Instruction]
    func fetchFrequentInstructions(limit: Int) async throws -> [Instruction]
    func fetchInstruction(id: Instruction.ID) async throws -> Instruction?
    func saveInstruction(_ instruction: Instruction) async throws
    func deleteInstruction(id: Instruction.ID) async throws
    func recordInstructionUsage(id: Instruction.ID) async throws
}

public enum RepositoryError: Error, Equatable, Sendable {
    case notFound
}
