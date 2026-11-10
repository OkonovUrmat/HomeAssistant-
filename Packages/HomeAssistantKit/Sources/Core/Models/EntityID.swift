import Foundation

/// A strongly typed identifier. `EntityID<KnowledgeItem>` and `EntityID<Instruction>`
/// are different types, so an instruction ID can never be passed where an item ID is expected.
public struct EntityID<Entity>: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue.uuidString }
}

extension EntityID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(UUID.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
