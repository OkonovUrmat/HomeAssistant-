import SwiftUI
import Observation
import Core
import DesignSystem

@MainActor
@Observable
public final class KnowledgeItemDetailViewModel {
    public struct Content {
        public var item: KnowledgeItem
        public var category: HouseCategory?
        public var breadcrumb: String
        public var hazard: HazardLevel
        public var related: [KnowledgeItem]
    }

    public enum State {
        case loading
        case loaded(Content)
        case notFound
        case failed(String)
    }

    public private(set) var state: State = .loading

    private let itemID: KnowledgeItem.ID
    private let itemRepository: any KnowledgeItemRepository
    private let categoryRepository: any CategoryRepository

    public init(
        itemID: KnowledgeItem.ID,
        itemRepository: any KnowledgeItemRepository,
        categoryRepository: any CategoryRepository
    ) {
        self.itemID = itemID
        self.itemRepository = itemRepository
        self.categoryRepository = categoryRepository
    }

    public var title: String {
        if case .loaded(let content) = state { return content.item.title }
        return ""
    }

    /// `nil` until the item has loaded.
    public var isFavorite: Bool? {
        if case .loaded(let content) = state { return content.item.isFavorite }
        return nil
    }

    public func load() async {
        do {
            guard let item = try await itemRepository.fetchItem(id: itemID) else {
                state = .notFound
                return
            }
            let tree = CategoryTree(try await categoryRepository.fetchCategories())
            var related: [KnowledgeItem] = []
            for relatedID in item.relatedItemIDs {
                if let relatedItem = try await itemRepository.fetchItem(id: relatedID) {
                    related.append(relatedItem)
                }
            }
            state = .loaded(Content(
                item: item,
                category: tree[item.categoryID],
                breadcrumb: tree.breadcrumb(for: item.categoryID),
                hazard: tree.effectiveHazard(of: item.categoryID),
                related: related
            ))
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    public func toggleFavorite() async {
        guard case .loaded(var content) = state else { return }
        content.item.isFavorite.toggle()
        state = .loaded(content)
        do {
            try await itemRepository.saveItem(content.item)
        } catch {
            content.item.isFavorite.toggle()
            state = .loaded(content)
        }
    }
}

/// Read-only item details. Gallery, document viewer, annotations and editing arrive in Phase 2–3.
public struct KnowledgeItemDetailView: View {
    @State private var viewModel: KnowledgeItemDetailViewModel

    public init(viewModel: KnowledgeItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .notFound:
                ContentUnavailableView("Not Found", systemImage: "questionmark.folder", description: Text("This item may have been deleted."))
            case .failed(let message):
                ContentUnavailableView("Couldn't Load", systemImage: "exclamationmark.triangle", description: Text(message))
            case .loaded(let content):
                list(content)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let isFavorite = viewModel.isFavorite ?? false
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .disabled(viewModel.isFavorite == nil)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .task { await viewModel.load() }
    }

    private func list(_ content: KnowledgeItemDetailViewModel.Content) -> some View {
        let item = content.item
        return List {
            Section {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(item.title)
                        .font(.title2.weight(.bold))
                    if !content.breadcrumb.isEmpty {
                        Text(content.breadcrumb)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ProvenanceBadge(item.provenance)
                    if content.hazard != .normal {
                        HazardBanner(content.hazard)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if !item.details.isEmpty {
                Section("Description") {
                    Text(item.details)
                }
            }

            if !item.notes.isEmpty {
                Section("Notes") {
                    Text(item.notes)
                }
            }

            if !item.attachments.isEmpty {
                Section("Attachments") {
                    ForEach(item.attachments) { attachment in
                        Label(attachment.fileName, systemImage: attachment.kind.symbolName)
                    }
                }
            }

            if !content.related.isEmpty {
                Section("Related") {
                    ForEach(content.related) { related in
                        NavigationLink(value: AppDestination.knowledgeItem(related.id)) {
                            Text(related.title)
                        }
                    }
                }
            }

            if !item.tags.isEmpty {
                Section("Tags") {
                    Text(item.tags.map { "#\($0)" }.joined(separator: "  "))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent("Added", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .listStyle(.insetGrouped)
    }
}
