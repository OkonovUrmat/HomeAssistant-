import Foundation

public struct Conversation: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<Conversation>

    public var id: ID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: ID = ID(), title: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ChatMessage: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<ChatMessage>

    public enum Role: String, Codable, Sendable { case user, assistant }
    public enum Status: String, Codable, Sendable { case streaming, complete, failed, cancelled }

    public var id: ID
    public var conversationID: Conversation.ID
    public var role: Role
    /// Markdown.
    public var content: String
    public var status: Status
    public var citations: [SourceCitation]
    public var createdAt: Date

    public init(
        id: ID = ID(),
        conversationID: Conversation.ID,
        role: Role,
        content: String,
        status: Status = .complete,
        citations: [SourceCitation] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.conversationID = conversationID
        self.role = role
        self.content = content
        self.status = status
        self.citations = citations
        self.createdAt = createdAt
    }
}

/// A reference from an answer back to the owner's material.
public struct SourceCitation: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<SourceCitation>

    public enum Target: Hashable, Codable, Sendable {
        case knowledgeItem(KnowledgeItem.ID)
        case attachment(item: KnowledgeItem.ID, attachment: Attachment.ID)
        case instruction(Instruction.ID)
    }

    public var id: ID
    public var target: Target
    public var title: String
    public var snippet: String?
    public var provenance: Provenance

    public init(id: ID = ID(), target: Target, title: String, snippet: String? = nil, provenance: Provenance) {
        self.id = id
        self.target = target
        self.title = title
        self.snippet = snippet
        self.provenance = provenance
    }

    /// Where tapping the citation should navigate.
    public var destination: AppDestination {
        switch target {
        case .knowledgeItem(let id): .knowledgeItem(id)
        case .attachment(let item, _): .knowledgeItem(item)
        case .instruction(let id): .instruction(id)
        }
    }
}
