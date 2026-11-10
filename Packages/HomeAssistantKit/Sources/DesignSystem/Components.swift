import SwiftUI
import Core

// MARK: - Card

public struct CardModifier: ViewModifier {
    var padding: CGFloat

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }
}

public extension View {
    /// Rounded surface used for grouped content on the dashboard.
    func dsCard(padding: CGFloat = DS.Spacing.m) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Icon badge

/// SF Symbol on a tinted rounded square, in the style of Apple Home accessories.
public struct IconBadge: View {
    let symbolName: String
    let tint: Color
    let size: CGFloat

    public init(symbolName: String, tint: Color, size: CGFloat = 36) {
        self.symbolName = symbolName
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Section header

public struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Badges & banners

public struct ProvenanceBadge: View {
    let provenance: Provenance

    public init(_ provenance: Provenance) {
        self.provenance = provenance
    }

    public var body: some View {
        Label(provenance.displayName, systemImage: provenance.symbolName)
            .font(.caption.weight(.medium))
            .foregroundStyle(provenance.color)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xxs)
            .background(provenance.color.opacity(0.12), in: Capsule())
    }
}

/// Shown at the top of any screen about a caution/dangerous system.
public struct HazardBanner: View {
    let hazard: HazardLevel

    public init(_ hazard: HazardLevel) {
        self.hazard = hazard
    }

    public var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s) {
            Image(systemName: hazard.symbolName)
                .font(.title3)
                .foregroundStyle(hazard.color)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(hazard.title).font(.subheadline.weight(.semibold))
                Text(hazard.guidance).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s)
        .background(hazard.color.opacity(0.10), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rows & tiles

/// Standard row: icon, title, subtitle, optional trailing accessory.
public struct DSRow<Trailing: View>: View {
    let symbolName: String
    let tint: Color
    let title: String
    let subtitle: String?
    let trailing: Trailing

    public init(
        symbolName: String,
        tint: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.symbolName = symbolName
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: DS.Spacing.s) {
            IconBadge(symbolName: symbolName, tint: tint, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: DS.Spacing.xs)
            trailing
        }
        .contentShape(Rectangle())
    }
}

public extension DSRow where Trailing == EmptyView {
    init(symbolName: String, tint: Color, title: String, subtitle: String? = nil) {
        self.init(symbolName: symbolName, tint: tint, title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// House system tile for the dashboard grid.
public struct SystemTile: View {
    let category: HouseCategory
    let subtitle: String

    public init(category: HouseCategory, subtitle: String) {
        self.category = category
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .top) {
                IconBadge(symbolName: category.symbolName, tint: category.tint.color, size: 40)
                Spacer()
                if category.hazard != .normal {
                    Image(systemName: category.hazard.symbolName)
                        .font(.footnote)
                        .foregroundStyle(category.hazard.color)
                        .accessibilityLabel(category.hazard.title)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .dsCard(padding: DS.Spacing.m - 2)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A container of rows separated by inset dividers, on a card surface.
public struct GroupedRows<Data: RandomAccessCollection, Row: View>: View where Data.Element: Identifiable {
    let data: Data
    let row: (Data.Element) -> Row

    public init(_ data: Data, @ViewBuilder row: @escaping (Data.Element) -> Row) {
        self.data = data
        self.row = row
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(data) { element in
                row(element)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.s - 2)
                if element.id != data.last?.id {
                    Divider().padding(.leading, DS.Spacing.m + 32 + DS.Spacing.s)
                }
            }
        }
        .dsCard(padding: 0)
    }
}

/// Small inline hint used when a dashboard section has nothing yet.
public struct InlineEmptyState: View {
    let symbolName: String
    let message: String

    public init(symbolName: String, message: String) {
        self.symbolName = symbolName
        self.message = message
    }

    public var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .dsCard()
    }
}
