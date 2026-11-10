import XCTest
import Core
@testable import Persistence

final class InMemoryStoreTests: XCTestCase {
    func testStandardTemplateSeedsSpecStructure() async throws {
        let store = InMemoryStore.seeded()
        let tree = CategoryTree(try await store.fetchCategories())

        XCTAssertEqual(tree.systems.map(\.name), ["Heating", "Water Supply", "Swimming Pool", "Electrical"])
        let water = try XCTUnwrap(tree.systems.first { $0.name == "Water Supply" })
        XCTAssertEqual(tree.children(of: water.id).map(\.name), ["Main Water Valve", "Storage Tanks", "Water Pump"])
        let electrical = try XCTUnwrap(tree.systems.first { $0.name == "Electrical" })
        XCTAssertEqual(electrical.hazard, .dangerous)
    }

    func testSeedWithoutSamplesHasNoContent() async throws {
        let store = InMemoryStore.seeded()
        let items = try await store.fetchItems(categoryID: nil)
        let instructions = try await store.fetchInstructions(categoryID: nil)
        XCTAssertTrue(items.isEmpty)
        XCTAssertTrue(instructions.isEmpty)
    }

    func testDeletingCategoryRemovesSubtreeAndContent() async throws {
        let store = InMemoryStore.seeded(includeSampleContent: true)
        let tree = CategoryTree(try await store.fetchCategories())
        let water = try XCTUnwrap(tree.systems.first { $0.name == "Water Supply" })
        let waterSubtree = Set([water.id] + tree.descendants(of: water.id).map(\.id))

        try await store.deleteCategory(id: water.id)

        let remaining = try await store.fetchCategories()
        XCTAssertTrue(remaining.allSatisfy { !waterSubtree.contains($0.id) })
        let items = try await store.fetchItems(categoryID: nil)
        XCTAssertTrue(items.allSatisfy { !waterSubtree.contains($0.categoryID) })
        let instructions = try await store.fetchInstructions(categoryID: nil)
        XCTAssertFalse(instructions.contains { $0.title.contains("storage tanks") })
    }

    func testFrequentInstructionsOrderedByUsage() async throws {
        let store = InMemoryStore.seeded(includeSampleContent: true)
        let all = try await store.fetchInstructions(categoryID: nil)
        let pool = try XCTUnwrap(all.first { $0.title.contains("pool") })

        for _ in 0..<10 { try await store.recordInstructionUsage(id: pool.id) }

        let frequent = try await store.fetchFrequentInstructions(limit: 1)
        XCTAssertEqual(frequent.first?.id, pool.id)
    }

    func testFavoritesAndRecent() async throws {
        let store = InMemoryStore.seeded(includeSampleContent: true)
        let favorites = try await store.fetchFavoriteItems()
        XCTAssertTrue(favorites.allSatisfy(\.isFavorite))
        let recent = try await store.fetchRecentItems(limit: 2)
        XCTAssertEqual(recent.count, 2)
        XCTAssertGreaterThanOrEqual(recent[0].createdAt, recent[1].createdAt)
    }

    func testDeletingMissingItemThrows() async {
        let store = InMemoryStore.seeded()
        do {
            try await store.deleteItem(id: KnowledgeItem.ID())
            XCTFail("Expected notFound")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }
}
