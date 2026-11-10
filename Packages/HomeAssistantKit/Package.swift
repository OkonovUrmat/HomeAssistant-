// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HomeAssistantKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "MediaManagement", targets: ["MediaManagement"]),
        .library(name: "DocumentProcessing", targets: ["DocumentProcessing"]),
        .library(name: "Dashboard", targets: ["Dashboard"]),
        .library(name: "KnowledgeBase", targets: ["KnowledgeBase"]),
        .library(name: "Instructions", targets: ["Instructions"]),
        .library(name: "AIChat", targets: ["AIChat"]),
    ],
    targets: [
        // Domain layer — Foundation only.
        .target(name: "Core"),

        // Shared UI.
        .target(name: "DesignSystem", dependencies: ["Core"]),

        // Data layer.
        .target(name: "Networking", dependencies: ["Core"]),
        .target(name: "Persistence", dependencies: ["Core"]),
        .target(name: "MediaManagement", dependencies: ["Core"]),
        .target(name: "DocumentProcessing", dependencies: ["Core"]),

        // Features — never depend on each other.
        .target(name: "Dashboard", dependencies: ["Core", "DesignSystem"]),
        .target(name: "KnowledgeBase", dependencies: ["Core", "DesignSystem"]),
        .target(name: "Instructions", dependencies: ["Core", "DesignSystem"]),
        .target(name: "AIChat", dependencies: ["Core", "DesignSystem"]),

        // Tests.
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Core"]),
    ]
)
