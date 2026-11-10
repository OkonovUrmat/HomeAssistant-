import Foundation
import Core

/// Stores attachment files under Application Support/Media, one file per attachment,
/// named by the attachment's UUID. The database only keeps the relative path.
public actor FileSystemMediaStore: MediaStore {
    private let rootDirectory: URL
    private let fileManager: FileManager

    public init(rootDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.rootDirectory = rootDirectory ?? URL.applicationSupportDirectory.appending(path: "Media", directoryHint: .isDirectory)
    }

    public func importFile(at url: URL, kind: AttachmentKind) async throws -> Attachment {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let attachmentID = Attachment.ID()
        let relativePath = Self.relativePath(for: attachmentID, fileExtension: url.pathExtension)
        let destination = try prepareDestination(relativePath)
        try fileManager.copyItem(at: url, to: destination)
        return Attachment(id: attachmentID, kind: kind, fileName: url.lastPathComponent, relativePath: relativePath)
    }

    public func importData(_ data: Data, fileExtension: String, kind: AttachmentKind) async throws -> Attachment {
        let attachmentID = Attachment.ID()
        let relativePath = Self.relativePath(for: attachmentID, fileExtension: fileExtension)
        let destination = try prepareDestination(relativePath)
        try data.write(to: destination, options: [.atomic, .completeFileProtection])
        let fileName = "\(kind.rawValue.capitalized) \(Date.now.formatted(date: .abbreviated, time: .shortened)).\(fileExtension)"
        return Attachment(id: attachmentID, kind: kind, fileName: fileName, relativePath: relativePath)
    }

    public func fileURL(for attachment: Attachment) async -> URL {
        rootDirectory.appending(path: attachment.relativePath, directoryHint: .notDirectory)
    }

    public func deleteFile(for attachment: Attachment) async throws {
        let url = await fileURL(for: attachment)
        if fileManager.fileExists(atPath: url.path(percentEncoded: false)) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Private

    private static func relativePath(for id: Attachment.ID, fileExtension: String) -> String {
        let ext = fileExtension.isEmpty ? "bin" : fileExtension.lowercased()
        // Two-character shard directory keeps any one folder small.
        let name = id.rawValue.uuidString.lowercased()
        return "\(name.prefix(2))/\(name).\(ext)"
    }

    private func prepareDestination(_ relativePath: String) throws -> URL {
        let destination = rootDirectory.appending(path: relativePath, directoryHint: .notDirectory)
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return destination
    }
}
