import SwiftUI
import Observation
import Core
import DesignSystem

@MainActor
@Observable
public final class InstructionsLibraryViewModel {
    public private(set) var instructions: [Instruction]?
    public private(set) var tree = CategoryTree([])
    public private(set) var errorMessage: String?
    public var searchText = ""

    private let instructionRepository: any InstructionRepository
    private let categoryRepository: any CategoryRepository

    public init(instructionRepository: any InstructionRepository, categoryRepository: any CategoryRepository) {
        self.instructionRepository = instructionRepository
        self.categoryRepository = categoryRepository
    }

    public var filtered: [Instruction] {
        let all = instructions ?? []
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    public func load() async {
        let instructionRepository = instructionRepository
        let categoryRepository = categoryRepository
        do {
            async let fetchedInstructions = instructionRepository.fetchInstructions(categoryID: nil)
            async let fetchedCategories = categoryRepository.fetchCategories()
            tree = CategoryTree(try await fetchedCategories)
            instructions = try await fetchedInstructions
            errorMessage = nil
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// The "Procedures" tab.
public struct InstructionsLibraryView: View {
    @State private var viewModel: InstructionsLibraryViewModel

    public init(viewModel: InstructionsLibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            if let instructions = viewModel.instructions {
                if instructions.isEmpty {
                    ContentUnavailableView(
                        "No Procedures Yet",
                        systemImage: "list.number",
                        description: Text("Write down how to operate your house — turning on heating, filling tanks, starting the pool pump.")
                    )
                } else {
                    list
                }
            } else if let message = viewModel.errorMessage {
                ContentUnavailableView("Couldn't Load", systemImage: "exclamationmark.triangle", description: Text(message))
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Procedures")
        .task { await viewModel.load() }
    }

    private var list: some View {
        List {
            ForEach(viewModel.filtered) { instruction in
                let category = instruction.categoryID.flatMap { viewModel.tree[$0] }
                NavigationLink(value: AppDestination.instruction(instruction.id)) {
                    DSRow(
                        symbolName: category?.symbolName ?? "list.number",
                        tint: category?.tint.color ?? .accentColor,
                        title: instruction.title,
                        subtitle: instruction.categoryID.map { viewModel.tree.breadcrumb(for: $0) }
                    ) {
                        if instruction.provenance == .aiSuggestion {
                            Image(systemName: Provenance.aiSuggestion.symbolName)
                                .foregroundStyle(Provenance.aiSuggestion.color)
                                .accessibilityLabel(Provenance.aiSuggestion.displayName)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search procedures")
        .overlay {
            if viewModel.filtered.isEmpty && !viewModel.searchText.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .refreshable { await viewModel.load() }
    }
}
