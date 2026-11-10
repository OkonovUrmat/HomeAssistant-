import Foundation

public struct House: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<House>

    public var id: ID
    public var name: String
    public var address: String?
    public var createdAt: Date

    public init(id: ID = ID(), name: String, address: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.address = address
        self.createdAt = createdAt
    }
}

/// Accent colour of a category. Kept as a semantic token so Core stays UI-framework free;
/// DesignSystem maps it to a SwiftUI `Color`.
public enum CategoryTint: String, Codable, Sendable, CaseIterable {
    case orange, red, yellow, green, teal, cyan, blue, indigo, purple, gray
}

/// A node in the house tree. Root nodes (no parent) are *systems* such as "Heating";
/// their descendants are *components* such as "Boiler". Depth is unlimited.
public struct HouseCategory: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<HouseCategory>

    public var id: ID
    public var parentID: ID?
    public var name: String
    /// SF Symbol name.
    public var symbolName: String
    public var tint: CategoryTint
    public var hazard: HazardLevel
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public var isSystem: Bool { parentID == nil }

    public init(
        id: ID = ID(),
        parentID: ID? = nil,
        name: String,
        symbolName: String,
        tint: CategoryTint,
        hazard: HazardLevel = .normal,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.parentID = parentID
        self.name = name
        self.symbolName = symbolName
        self.tint = tint
        self.hazard = hazard
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
