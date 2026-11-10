import SwiftUI
import Core
import DesignSystem

public struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    private let onAskAssistant: () -> Void
    private let onAddContent: () -> Void
    private let onShowAllInstructions: () -> Void

    public init(
        viewModel: DashboardViewModel,
        onAskAssistant: @escaping () -> Void,
        onAddContent: @escaping () -> Void,
        onShowAllInstructions: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onAskAssistant = onAskAssistant
        self.onAddContent = onAddContent
        self.onShowAllInstructions = onShowAllInstructions
    }

    public var body: some View {
        content
            .background(DS.Colors.background)
            .navigationTitle(viewModel.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onAddContent) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add to knowledge base")
                }
            }
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load your house", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let snapshot):
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    AskAssistantCard(action: onAskAssistant)
                    if snapshot.isEmpty {
                        GettingStartedCard(action: onAddContent)
                    }
                    systemsSection(snapshot)
                    quickAccessSection(snapshot)
                    instructionsSection(snapshot)
                    recentSection(snapshot)
                }
                .padding(.horizontal, DS.Spacing.m)
                .padding(.top, DS.Spacing.xs)
                .padding(.bottom, DS.Spacing.xxl)
            }
            .refreshable { await viewModel.load() }
        }
    }

    // MARK: - Sections

    private func systemsSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            SectionHeader("Systems")
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160), spacing: DS.Spacing.s)],
                spacing: DS.Spacing.s
            ) {
                ForEach(snapshot.systems) { system in
                    NavigationLink(value: AppDestination.category(system.id)) {
                        SystemTile(category: system.category, subtitle: system.subtitle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickAccessSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            SectionHeader("Quick Access")
            if snapshot.quickAccess.isEmpty {
                InlineEmptyState(
                    symbolName: "star",
                    message: "Mark important components as favorites — like the main shutoff — to reach them here in one tap."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s) {
                        ForEach(snapshot.quickAccess) { item in
                            NavigationLink(value: AppDestination.knowledgeItem(item.id)) {
                                QuickAccessChip(item: item, category: snapshot.category(item.categoryID))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    private func instructionsSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            SectionHeader(
                "Frequently Used",
                actionTitle: snapshot.totalInstructions > 0 ? "See All" : nil,
                action: onShowAllInstructions
            )
            if snapshot.frequentInstructions.isEmpty {
                InlineEmptyState(
                    symbolName: "list.number",
                    message: "Procedures you write — like starting the heating — will appear here."
                )
            } else {
                GroupedRows(snapshot.frequentInstructions) { instruction in
                    NavigationLink(value: AppDestination.instruction(instruction.id)) {
                        let category = snapshot.category(instruction.categoryID)
                        DSRow(
                            symbolName: "list.number",
                            tint: category?.tint.color ?? .accentColor,
                            title: instruction.title,
                            subtitle: "\(instruction.steps.count) steps · \(snapshot.location(of: instruction.categoryID))"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func recentSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            SectionHeader("Recently Added")
            if snapshot.recentItems.isEmpty {
                InlineEmptyState(
                    symbolName: "photo.on.rectangle.angled",
                    message: "Photos, manuals and notes you add will show up here."
                )
            } else {
                GroupedRows(snapshot.recentItems) { item in
                    NavigationLink(value: AppDestination.knowledgeItem(item.id)) {
                        let category = snapshot.category(item.categoryID)
                        DSRow(
                            symbolName: category?.symbolName ?? "doc",
                            tint: category?.tint.color ?? .accentColor,
                            title: item.title,
                            subtitle: snapshot.location(of: item.categoryID)
                        ) {
                            Text(item.createdAt, format: .relative(presentation: .named))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Subviews

private struct AskAssistantCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask about your house")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("“How do I fill the tanks from city water?”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .dsCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the assistant")
    }
}

private struct GettingStartedCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Start your house manual")
                .font(.headline)
            Text("Photograph your boiler, valves and electrical panel, add manuals and notes. The assistant answers only from what you add here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(action: action) {
                Label("Add First Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, DS.Spacing.xxs)
        }
        .dsCard()
    }
}

private struct QuickAccessChip: View {
    let item: KnowledgeItem
    let category: HouseCategory?

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            IconBadge(
                symbolName: category?.symbolName ?? "star.fill",
                tint: category?.tint.color ?? .accentColor,
                size: 28
            )
            Text(item.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.leading, DS.Spacing.xs)
        .padding(.trailing, DS.Spacing.s)
        .padding(.vertical, DS.Spacing.xs)
        .background(DS.Colors.surface, in: Capsule())
    }
}
