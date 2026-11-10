import SwiftUI
import Core

/// Design tokens. Typography uses the system text styles so Dynamic Type works everywhere.
public enum DS {
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 20
        public static let xl: CGFloat = 28
        public static let xxl: CGFloat = 36
    }

    public enum Radius {
        public static let small: CGFloat = 10
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 22
    }

    public enum Colors {
        public static let background = Color(.systemGroupedBackground)
        public static let surface = Color(.secondarySystemGroupedBackground)
        public static let separator = Color(.separator)
        public static let secondaryText = Color.secondary
    }

    public enum Motion {
        public static let standard = Animation.snappy(duration: 0.25)
    }
}

public extension CategoryTint {
    var color: Color {
        switch self {
        case .orange: .orange
        case .red: .red
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .gray: .gray
        }
    }
}

public extension HazardLevel {
    var color: Color {
        switch self {
        case .normal: .secondary
        case .caution: .orange
        case .dangerous: .red
        }
    }

    var symbolName: String {
        switch self {
        case .normal: "checkmark.shield"
        case .caution: "exclamationmark.triangle.fill"
        case .dangerous: "bolt.trianglebadge.exclamationmark.fill"
        }
    }

    var title: String {
        switch self {
        case .normal: "No special hazard"
        case .caution: "Use caution"
        case .dangerous: "Hazardous system"
        }
    }

    var guidance: String {
        switch self {
        case .normal:
            ""
        case .caution:
            "This system may be under pressure or hot. Follow only documented procedures."
        case .dangerous:
            "Work on this system can cause serious injury. Follow documented procedures only, and call a qualified professional when in doubt."
        }
    }
}

public extension Provenance {
    var color: Color {
        switch self {
        case .verifiedInstruction: .green
        case .userNote: .blue
        case .manufacturerDocument: .indigo
        case .aiSuggestion: .orange
        }
    }

    var symbolName: String {
        switch self {
        case .verifiedInstruction: "checkmark.seal.fill"
        case .userNote: "note.text"
        case .manufacturerDocument: "building.2"
        case .aiSuggestion: "sparkles"
        }
    }
}
