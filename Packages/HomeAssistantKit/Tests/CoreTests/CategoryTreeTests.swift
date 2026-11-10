import XCTest
@testable import Core

final class CategoryTreeTests: XCTestCase {
    private func makeTree() -> (CategoryTree, heating: HouseCategory, boiler: HouseCategory, burner: HouseCategory, electrical: HouseCategory) {
        let heating = HouseCategory(name: "Heating", symbolName: "flame", tint: .orange, hazard: .caution, sortOrder: 0)
        let boiler = HouseCategory(parentID: heating.id, name: "Boiler", symbolName: "flame", tint: .orange, sortOrder: 0)
        let burner = HouseCategory(parentID: boiler.id, name: "Burner", symbolName: "flame", tint: .orange, sortOrder: 0)
        let radiators = HouseCategory(parentID: heating.id, name: "Radiators", symbolName: "heater", tint: .orange, sortOrder: 1)
        let electrical = HouseCategory(name: "Electrical", symbolName: "bolt", tint: .yellow, hazard: .dangerous, sortOrder: 1)
        let tree = CategoryTree([radiators, electrical, burner, boiler, heating])
        return (tree, heating, boiler, burner, electrical)
    }

    func testSystemsAreRootsInSortOrder() {
        let (tree, heating, _, _, electrical) = makeTree()
        XCTAssertEqual(tree.systems.map(\.id), [heating.id, electrical.id])
    }

    func testDescendantsAreDepthFirst() {
        let (tree, heating, boiler, burner, _) = makeTree()
        XCTAssertEqual(tree.descendants(of: heating.id).map(\.name), ["Boiler", "Burner", "Radiators"])
        XCTAssertEqual(tree.descendants(of: boiler.id).map(\.id), [burner.id])
    }

    func testPathAndBreadcrumb() {
        let (tree, heating, _, burner, _) = makeTree()
        XCTAssertEqual(tree.breadcrumb(for: burner.id), "Heating › Boiler › Burner")
        XCTAssertEqual(tree.system(containing: burner.id)?.id, heating.id)
    }

    func testHazardIsInheritedFromAncestors() {
        let (tree, _, _, burner, electrical) = makeTree()
        XCTAssertEqual(tree.effectiveHazard(of: burner.id), .caution)
        XCTAssertEqual(tree.effectiveHazard(of: electrical.id), .dangerous)
    }

    func testOrphansArePromotedToRoots() {
        let orphan = HouseCategory(parentID: HouseCategory.ID(), name: "Orphan", symbolName: "questionmark", tint: .gray)
        let tree = CategoryTree([orphan])
        XCTAssertEqual(tree.systems.map(\.id), [orphan.id])
    }

    func testCycleDoesNotHang() {
        var a = HouseCategory(name: "A", symbolName: "a.circle", tint: .gray)
        let b = HouseCategory(parentID: a.id, name: "B", symbolName: "b.circle", tint: .gray)
        a.parentID = b.id
        let tree = CategoryTree([a, b])
        XCTAssertLessThanOrEqual(tree.path(to: a.id).count, 2)
    }

    func testEntityIDEncodesAsPlainUUID() throws {
        let id = KnowledgeItem.ID()
        let data = try JSONEncoder().encode([id])
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(json, "[\"\(id.rawValue.uuidString)\"]")
        XCTAssertEqual(try JSONDecoder().decode([KnowledgeItem.ID].self, from: data), [id])
    }
}
