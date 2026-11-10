import SwiftUI
import Core
import DesignSystem

/// The "Assistant" tab. The streaming chat (backend, RAG, citations) is built in Phase 4;
/// until then the tab explains what it will do and how answers are grounded.
public struct AssistantHomeView: View {
    private let isConnected: Bool

    public init(isConnected: Bool = false) {
        self.isConnected = isConnected
    }

    public static let suggestedQuestions = [
        "How do I turn on the heating?",
        "How do I fill the water tanks from city water?",
        "Which breaker controls the pool pump?",
        "What should I check if the radiators are cold?",
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentColor)
                    Text("Answers from your own house manual")
                        .font(.title2.weight(.bold))
                    Text("The assistant searches your photos, documents, notes and procedures, and cites where each answer comes from. If something isn't documented, it says so instead of guessing.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    SectionHeader("Try asking")
                    GroupedRows(Self.suggestedQuestions.map(SuggestedQuestion.init)) { question in
                        DSRow(symbolName: "text.bubble", tint: .accentColor, title: question.text)
                            .opacity(isConnected ? 1 : 0.5)
                    }
                }

                if !isConnected {
                    InlineEmptyState(
                        symbolName: "bolt.horizontal.circle",
                        message: "The assistant isn't connected yet. Keep adding to your knowledge base — everything you add will be searchable once it is."
                    )
                }
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Colors.background)
        .navigationTitle("Assistant")
    }
}

private struct SuggestedQuestion: Identifiable {
    let text: String
    var id: String { text }
}
