import Foundation
import PDFKit
import Vision
import Core

/// Extracts text for search and RAG:
/// - PDFs: embedded text via PDFKit (scanned PDFs get OCR in Phase 5).
/// - Photos and diagrams: on-device OCR via Vision.
public struct DocumentTextExtractor: TextExtractor {
    public var recognitionLanguages: [String]

    public init(recognitionLanguages: [String] = ["en-US", "ru-RU"]) {
        self.recognitionLanguages = recognitionLanguages
    }

    public func extractText(from url: URL, kind: AttachmentKind) async throws -> String? {
        switch kind {
        case .pdf:
            return Self.pdfText(at: url)
        case .photo, .diagram:
            return try await recognizeText(in: url)
        case .document:
            return try? String(contentsOf: url, encoding: .utf8)
        case .video:
            return nil
        }
    }

    private static func pdfText(at url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        let pages = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }
        let text = pages.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    /// Runs synchronously on the caller's (non-main) executor; `perform` returns once
    /// recognition is complete, so no completion handler or continuation is needed.
    private func recognizeText(in url: URL) async throws -> String? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = recognitionLanguages

        try VNImageRequestHandler(url: url).perform([request])

        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }
}
