import SwiftUI
import DesignSystem

/// Entry point for adding anything to the knowledge base, presented as a sheet from every tab.
/// Phase 1 defines the sources; importing and the item editor are implemented in Phase 2.
public struct UploadCenterView: View {
    public enum Source: String, CaseIterable, Identifiable {
        case camera, photoLibrary, scanDocument, files, video, note

        public var id: String { rawValue }

        var title: String {
            switch self {
            case .camera: "Take Photo"
            case .photoLibrary: "Photo Library"
            case .scanDocument: "Scan Document"
            case .files: "PDF or File"
            case .video: "Video"
            case .note: "Text Note"
            }
        }

        var subtitle: String {
            switch self {
            case .camera: "Equipment, valves, labels"
            case .photoLibrary: "Photos you've already taken"
            case .scanDocument: "Paper manuals and service records"
            case .files: "Manuals, diagrams, invoices"
            case .video: "Walkthroughs and procedures"
            case .note: "Anything you want to remember"
            }
        }

        var symbolName: String {
            switch self {
            case .camera: "camera"
            case .photoLibrary: "photo.on.rectangle"
            case .scanDocument: "doc.viewfinder"
            case .files: "doc.richtext"
            case .video: "video"
            case .note: "square.and.pencil"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    private let onSelect: (Source) -> Void
    private let availableSources: Set<Source>

    public init(availableSources: Set<Source> = [], onSelect: @escaping (Source) -> Void = { _ in }) {
        self.availableSources = availableSources
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Source.allCases) { source in
                        Button {
                            onSelect(source)
                        } label: {
                            DSRow(symbolName: source.symbolName, tint: .accentColor, title: source.title, subtitle: source.subtitle)
                        }
                        .disabled(!availableSources.contains(source))
                    }
                } footer: {
                    if availableSources.isEmpty {
                        Text("Importing is coming soon. Everything you add stays private to your house.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add to House")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
