import Foundation
import Core
import Persistence
import MediaManagement
import DocumentProcessing
import Dashboard
import KnowledgeBase
import Instructions

/// Composition root: the one place that knows which concrete type backs each protocol.
/// Features receive protocols only, so tests and previews can inject anything.
@MainActor
final class AppContainer {
    let houseRepository: any HouseRepository
    let categoryRepository: any CategoryRepository
    let itemRepository: any KnowledgeItemRepository
    let instructionRepository: any InstructionRepository
    let mediaStore: any MediaStore
    let textExtractor: any TextExtractor

    init(
        houseRepository: any HouseRepository,
        categoryRepository: any CategoryRepository,
        itemRepository: any KnowledgeItemRepository,
        instructionRepository: any InstructionRepository,
        mediaStore: any MediaStore,
        textExtractor: any TextExtractor
    ) {
        self.houseRepository = houseRepository
        self.categoryRepository = categoryRepository
        self.itemRepository = itemRepository
        self.instructionRepository = instructionRepository
        self.mediaStore = mediaStore
        self.textExtractor = textExtractor
    }

    /// Phase 1: in-memory store seeded with the default house structure.
    /// Pass `-sampleData` as a launch argument (set in the Debug scheme) to add demo content.
    static func live() -> AppContainer {
        #if DEBUG
        let includeSamples = ProcessInfo.processInfo.arguments.contains("-sampleData")
        #else
        let includeSamples = false
        #endif
        let store = InMemoryStore.seeded(with: .standard, includeSampleContent: includeSamples)
        return AppContainer(
            houseRepository: store,
            categoryRepository: store,
            itemRepository: store,
            instructionRepository: store,
            mediaStore: FileSystemMediaStore(),
            textExtractor: DocumentTextExtractor()
        )
    }

    static func preview() -> AppContainer {
        let store = InMemoryStore.seeded(with: .standard, includeSampleContent: true)
        return AppContainer(
            houseRepository: store,
            categoryRepository: store,
            itemRepository: store,
            instructionRepository: store,
            mediaStore: FileSystemMediaStore(rootDirectory: FileManager.default.temporaryDirectory),
            textExtractor: DocumentTextExtractor()
        )
    }

    // MARK: - View model factories

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            houseRepository: houseRepository,
            categoryRepository: categoryRepository,
            itemRepository: itemRepository,
            instructionRepository: instructionRepository
        )
    }

    func makeHouseBrowserViewModel() -> HouseBrowserViewModel {
        HouseBrowserViewModel(categoryRepository: categoryRepository)
    }

    func makeCategoryDetailViewModel(id: HouseCategory.ID) -> CategoryDetailViewModel {
        CategoryDetailViewModel(
            categoryID: id,
            categoryRepository: categoryRepository,
            itemRepository: itemRepository,
            instructionRepository: instructionRepository
        )
    }

    func makeKnowledgeItemDetailViewModel(id: KnowledgeItem.ID) -> KnowledgeItemDetailViewModel {
        KnowledgeItemDetailViewModel(itemID: id, itemRepository: itemRepository, categoryRepository: categoryRepository)
    }

    func makeInstructionsLibraryViewModel() -> InstructionsLibraryViewModel {
        InstructionsLibraryViewModel(instructionRepository: instructionRepository, categoryRepository: categoryRepository)
    }

    func makeInstructionDetailViewModel(id: Instruction.ID) -> InstructionDetailViewModel {
        InstructionDetailViewModel(instructionID: id, instructionRepository: instructionRepository, categoryRepository: categoryRepository)
    }
}
