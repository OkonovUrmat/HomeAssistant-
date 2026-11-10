import Foundation

/// An operational procedure, e.g. "Filling the storage tanks from city water".
///
/// Instructions are never invented by the app: they come from the owner, or — if generated
/// by the assistant — carry `.aiSuggestion` provenance and are shown as unverified.
public struct Instruction: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<Instruction>

    public var id: ID
    public var categoryID: HouseCategory.ID?
    public var relatedItemIDs: [KnowledgeItem.ID]
    public var title: String
    public var summary: String
    public var requiredEquipment: [String]
    public var preconditions: [String]
    public var steps: [InstructionStep]
    public var warnings: [String]
    public var expectedResult: String
    public var troubleshooting: [TroubleshootingTip]
    public var provenance: Provenance
    public var isFavorite: Bool
    public var usageCount: Int
    public var lastUsedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        categoryID: HouseCategory.ID? = nil,
        relatedItemIDs: [KnowledgeItem.ID] = [],
        title: String,
        summary: String = "",
        requiredEquipment: [String] = [],
        preconditions: [String] = [],
        steps: [InstructionStep] = [],
        warnings: [String] = [],
        expectedResult: String = "",
        troubleshooting: [TroubleshootingTip] = [],
        provenance: Provenance = .userNote,
        isFavorite: Bool = false,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.categoryID = categoryID
        self.relatedItemIDs = relatedItemIDs
        self.title = title
        self.summary = summary
        self.requiredEquipment = requiredEquipment
        self.preconditions = preconditions
        self.steps = steps
        self.warnings = warnings
        self.expectedResult = expectedResult
        self.troubleshooting = troubleshooting
        self.provenance = provenance
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct InstructionStep: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<InstructionStep>

    public var id: ID
    public var text: String
    /// Photo illustrating this step, stored on the instruction's related item.
    public var attachmentID: Attachment.ID?
    public var warning: String?

    public init(id: ID = ID(), text: String, attachmentID: Attachment.ID? = nil, warning: String? = nil) {
        self.id = id
        self.text = text
        self.attachmentID = attachmentID
        self.warning = warning
    }
}

public struct TroubleshootingTip: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<TroubleshootingTip>

    public var id: ID
    public var problem: String
    public var solution: String

    public init(id: ID = ID(), problem: String, solution: String) {
        self.id = id
        self.problem = problem
        self.solution = solution
    }
}
