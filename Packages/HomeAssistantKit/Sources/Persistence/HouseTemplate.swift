import Foundation
import Core

/// The starting structure of a new house. Purely organisational: it creates empty
/// categories, never technical content.
public struct HouseTemplate: Sendable {
    public struct Node: Sendable {
        public var name: String
        public var symbolName: String
        public var tint: CategoryTint
        public var hazard: HazardLevel
        public var children: [Node]

        public init(
            _ name: String,
            symbol: String,
            tint: CategoryTint,
            hazard: HazardLevel = .normal,
            children: [Node] = []
        ) {
            self.name = name
            self.symbolName = symbol
            self.tint = tint
            self.hazard = hazard
            self.children = children
        }
    }

    public var houseName: String
    public var systems: [Node]

    public init(houseName: String, systems: [Node]) {
        self.houseName = houseName
        self.systems = systems
    }

    /// Flattens the template into categories with parent links and sort order.
    public func makeCategories(now: Date = .now) -> [HouseCategory] {
        var result: [HouseCategory] = []

        func append(_ nodes: [Node], parentID: HouseCategory.ID?) {
            for (index, node) in nodes.enumerated() {
                let category = HouseCategory(
                    parentID: parentID,
                    name: node.name,
                    symbolName: node.symbolName,
                    tint: node.tint,
                    hazard: node.hazard,
                    sortOrder: index,
                    createdAt: now,
                    updatedAt: now
                )
                result.append(category)
                append(node.children, parentID: category.id)
            }
        }

        append(systems, parentID: nil)
        return result
    }
}

public extension HouseTemplate {
    /// The default tree from the product spec.
    static let standard = HouseTemplate(
        houseName: "My House",
        systems: [
            Node("Heating", symbol: "flame", tint: .orange, hazard: .caution, children: [
                Node("Boiler", symbol: "flame.fill", tint: .orange, hazard: .caution),
                Node("Circulation Pump", symbol: "arrow.triangle.2.circlepath", tint: .orange),
                Node("Radiators", symbol: "thermometer.medium", tint: .orange),
            ]),
            Node("Water Supply", symbol: "drop.fill", tint: .blue, children: [
                Node("Main Water Valve", symbol: "spigot", tint: .blue),
                Node("Storage Tanks", symbol: "cylinder", tint: .blue),
                Node("Water Pump", symbol: "gearshape.2", tint: .blue),
            ]),
            Node("Swimming Pool", symbol: "figure.pool.swim", tint: .cyan, children: [
                Node("Filtration System", symbol: "line.3.horizontal.decrease.circle", tint: .cyan),
                Node("Pool Pump", symbol: "gearshape.2", tint: .cyan),
                Node("Valves", symbol: "dial.medium", tint: .cyan),
            ]),
            Node("Electrical", symbol: "bolt.fill", tint: .yellow, hazard: .dangerous, children: [
                Node("Main Electrical Panel", symbol: "square.grid.3x3", tint: .yellow, hazard: .dangerous),
                Node("Circuit Breakers", symbol: "switch.2", tint: .yellow, hazard: .dangerous),
            ]),
        ]
    )

    /// Systems the owner can add with one tap (Phase 2 "Add system" sheet).
    static let suggestedSystems: [Node] = [
        Node("Ventilation", symbol: "wind", tint: .teal),
        Node("Air Conditioning", symbol: "snowflake", tint: .cyan),
        Node("Plumbing", symbol: "wrench.and.screwdriver", tint: .blue),
        Node("Sewage", symbol: "arrow.down.to.line", tint: .gray),
        Node("Gas", symbol: "flame", tint: .red, hazard: .dangerous),
        Node("Security", symbol: "lock.shield", tint: .indigo),
        Node("Internet & Networking", symbol: "wifi", tint: .purple),
        Node("Smart Home", symbol: "lightswitch.on", tint: .purple),
        Node("Garden Irrigation", symbol: "leaf", tint: .green),
        Node("Generator", symbol: "powerplug", tint: .red, hazard: .dangerous),
        Node("Solar Panels", symbol: "sun.max", tint: .yellow, hazard: .dangerous),
    ]
}
