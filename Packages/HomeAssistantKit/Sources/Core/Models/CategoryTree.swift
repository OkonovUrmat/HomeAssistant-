import Foundation

/// Read-only tree view over a flat list of categories.
public struct CategoryTree: Sendable {
    public let categoriesByID: [HouseCategory.ID: HouseCategory]
    private let childIDsByParent: [HouseCategory.ID?: [HouseCategory.ID]]

    public init(_ categories: [HouseCategory]) {
        var byID: [HouseCategory.ID: HouseCategory] = [:]
        for category in categories { byID[category.id] = category }

        var children: [HouseCategory.ID?: [HouseCategory]] = [:]
        for category in categories {
            // Orphans (parent deleted or missing) are promoted to roots so data is never hidden.
            let parent = category.parentID.flatMap { byID[$0] == nil ? nil : $0 }
            children[parent, default: []].append(category)
        }

        categoriesByID = byID
        childIDsByParent = children.mapValues { siblings in
            siblings.sorted(by: Self.displayOrder).map(\.id)
        }
    }

    public static func displayOrder(_ lhs: HouseCategory, _ rhs: HouseCategory) -> Bool {
        if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    public subscript(id: HouseCategory.ID) -> HouseCategory? { categoriesByID[id] }

    /// Top-level systems.
    public var systems: [HouseCategory] { children(of: nil) }

    public func children(of id: HouseCategory.ID?) -> [HouseCategory] {
        (childIDsByParent[id] ?? []).compactMap { categoriesByID[$0] }
    }

    /// All descendants, depth-first, excluding the node itself.
    public func descendants(of id: HouseCategory.ID) -> [HouseCategory] {
        children(of: id).flatMap { [$0] + descendants(of: $0.id) }
    }

    /// Path from the root system down to (and including) the node.
    public func path(to id: HouseCategory.ID) -> [HouseCategory] {
        var path: [HouseCategory] = []
        var visited: Set<HouseCategory.ID> = []
        var current = categoriesByID[id]
        while let node = current, !visited.contains(node.id) {
            visited.insert(node.id)
            path.insert(node, at: 0)
            current = node.parentID.flatMap { categoriesByID[$0] }
        }
        return path
    }

    /// The top-level system a node belongs to.
    public func system(containing id: HouseCategory.ID) -> HouseCategory? {
        path(to: id).first
    }

    /// The strictest hazard level on the path — a breaker inside "Electrical" inherits "dangerous".
    public func effectiveHazard(of id: HouseCategory.ID) -> HazardLevel {
        path(to: id).map(\.hazard).max() ?? .normal
    }

    /// "Heating › Boiler"
    public func breadcrumb(for id: HouseCategory.ID, separator: String = " › ") -> String {
        path(to: id).map(\.name).joined(separator: separator)
    }
}
