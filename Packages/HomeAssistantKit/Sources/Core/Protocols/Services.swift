import Foundation

/// Stores attachment files on disk.
public protocol MediaStore: Sendable {
    /// Copies the file into the app's media directory and returns attachment metadata.
    func importFile(at url: URL, kind: AttachmentKind) async throws -> Attachment
    func importData(_ data: Data, fileExtension: String, kind: AttachmentKind) async throws -> Attachment
    func fileURL(for attachment: Attachment) async -> URL
    func deleteFile(for attachment: Attachment) async throws
}

/// Extracts searchable text from documents and images (PDFKit, Vision OCR).
public protocol TextExtractor: Sendable {
    /// Returns `nil` when the file type has no extractable text.
    func extractText(from url: URL, kind: AttachmentKind) async throws -> String?
}

/// Events streamed from the assistant backend (Phase 4).
public enum AssistantEvent: Sendable, Equatable {
    /// A chunk of markdown to append to the answer.
    case textDelta(String)
    /// A source the answer is grounded in.
    case citation(SourceCitation)
    /// The backend found nothing relevant in the knowledge base.
    case insufficientInformation
    case finished
}

/// The only door to the AI. Views and view models never call an LLM API directly;
/// the implementation talks to our backend, which holds the keys and runs RAG.
public protocol AssistantService: Sendable {
    func streamAnswer(
        to question: String,
        in conversationID: Conversation.ID
    ) -> AsyncThrowingStream<AssistantEvent, Error>
}
