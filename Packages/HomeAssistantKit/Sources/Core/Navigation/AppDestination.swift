import Foundation

/// Every screen that can be pushed onto a navigation stack.
///
/// Features emit destinations (e.g. `NavigationLink(value: AppDestination.category(id))`);
/// the App target resolves them to concrete views. This keeps feature modules independent:
/// Dashboard can link to a knowledge item without importing KnowledgeBase.
public enum AppDestination: Hashable, Sendable {
    case category(HouseCategory.ID)
    case knowledgeItem(KnowledgeItem.ID)
    case instruction(Instruction.ID)
}
