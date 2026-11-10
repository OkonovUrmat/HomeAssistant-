import Foundation

public struct KnowledgeItem: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<KnowledgeItem>

    public var id: ID
    public var categoryID: HouseCategory.ID
    public var title: String
    /// Short description shown in lists and sent to the AI as context.
    public var details: String
    /// Free-form personal notes.
    public var notes: String
    public var tags: [String]
    public var provenance: Provenance
    public var isFavorite: Bool
    public var attachments: [Attachment]
    public var relatedItemIDs: [ID]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        categoryID: HouseCategory.ID,
        title: String,
        details: String = "",
        notes: String = "",
        tags: [String] = [],
        provenance: Provenance = .userNote,
        isFavorite: Bool = false,
        attachments: [Attachment] = [],
        relatedItemIDs: [ID] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.categoryID = categoryID
        self.title = title
        self.details = details
        self.notes = notes
        self.tags = tags
        self.provenance = provenance
        self.isFavorite = isFavorite
        self.attachments = attachments
        self.relatedItemIDs = relatedItemIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// First photo or diagram, used as the item's cover image.
    public var coverAttachment: Attachment? {
        attachments.first { $0.kind == .photo || $0.kind == .diagram }
    }
}

public enum AttachmentKind: String, Codable, Sendable, CaseIterable {
    case photo, video, pdf, diagram, document

    public var symbolName: String {
        switch self {
        case .photo: "photo"
        case .video: "video"
        case .pdf: "doc.richtext"
        case .diagram: "point.3.connected.trianglepath.dotted"
        case .document: "doc.text"
        }
    }
}

/// A file stored on disk. The database keeps only metadata and a path relative to the
/// media directory, so the container can move (backups, reinstall) without breaking links.
public struct Attachment: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<Attachment>

    public var id: ID
    public var kind: AttachmentKind
    /// Original file name shown to the user.
    public var fileName: String
    /// Path relative to the media root directory.
    public var relativePath: String
    public var caption: String
    /// Text extracted by PDFKit / OCR, indexed for search and RAG.
    public var extractedText: String?
    public var annotations: [PhotoAnnotation]
    public var createdAt: Date

    public init(
        id: ID = ID(),
        kind: AttachmentKind,
        fileName: String,
        relativePath: String,
        caption: String = "",
        extractedText: String? = nil,
        annotations: [PhotoAnnotation] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.relativePath = relativePath
        self.caption = caption
        self.extractedText = extractedText
        self.annotations = annotations
        self.createdAt = createdAt
    }
}

/// A point expressed as a fraction of the image size (0…1), so annotations survive resizing.
public struct NormalizedPoint: Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = min(max(x, 0), 1)
        self.y = min(max(y, 0), 1)
    }
}

/// A marker on a photo, e.g. "Valve 1 — City water input". Tapping it reveals `detail`.
public struct PhotoAnnotation: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = EntityID<PhotoAnnotation>

    public enum Style: String, Codable, Sendable {
        case numberedMarker, arrow, label, text
    }

    public var id: ID
    public var style: Style
    public var number: Int?
    public var label: String
    public var detail: String
    public var position: NormalizedPoint
    /// End point for arrows.
    public var arrowEnd: NormalizedPoint?
    /// Optional link to the component this marker shows (e.g. the valve's own category).
    public var linkedCategoryID: HouseCategory.ID?

    public init(
        id: ID = ID(),
        style: Style,
        number: Int? = nil,
        label: String,
        detail: String = "",
        position: NormalizedPoint,
        arrowEnd: NormalizedPoint? = nil,
        linkedCategoryID: HouseCategory.ID? = nil
    ) {
        self.id = id
        self.style = style
        self.number = number
        self.label = label
        self.detail = detail
        self.position = position
        self.arrowEnd = arrowEnd
        self.linkedCategoryID = linkedCategoryID
    }
}
