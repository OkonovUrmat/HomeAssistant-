import Foundation
import Core

/// Demo content for previews and Debug runs (`-sampleData` launch argument).
///
/// Deliberately generic: no valve positions, pressures or breaker numbers, because
/// invented technical values are exactly what this app must never show.
public enum SampleContent {
    public static func make(for categories: [HouseCategory]) -> (items: [KnowledgeItem], instructions: [Instruction]) {
        func id(_ name: String) -> HouseCategory.ID? {
            categories.first { $0.name == name }?.id
        }

        guard
            let boiler = id("Boiler"),
            let tanks = id("Storage Tanks"),
            let mainValve = id("Main Water Valve"),
            let filtration = id("Filtration System"),
            let panel = id("Main Electrical Panel")
        else { return ([], []) }

        let day: TimeInterval = 86_400
        let now = Date.now

        let boilerItem = KnowledgeItem(
            categoryID: boiler,
            title: "Boiler overview",
            details: "Wall-mounted gas boiler in the utility room. Manual stored in the drawer below.",
            notes: "Service company phone number is on the sticker on the side panel.",
            tags: ["boiler", "utility room"],
            provenance: .userNote,
            isFavorite: true,
            createdAt: now.addingTimeInterval(-6 * day),
            updatedAt: now.addingTimeInterval(-2 * day)
        )
        let valvesItem = KnowledgeItem(
            categoryID: tanks,
            title: "Water distribution valves",
            details: "Valves between the city supply, the storage tanks and the house.",
            tags: ["valves", "tanks", "city water"],
            provenance: .userNote,
            isFavorite: true,
            createdAt: now.addingTimeInterval(-3 * day),
            updatedAt: now.addingTimeInterval(-3 * day)
        )
        let shutoffItem = KnowledgeItem(
            categoryID: mainValve,
            title: "Main shutoff location",
            details: "Location of the main water shutoff.",
            tags: ["shutoff", "emergency"],
            provenance: .userNote,
            isFavorite: true,
            createdAt: now.addingTimeInterval(-1 * day),
            updatedAt: now.addingTimeInterval(-1 * day)
        )
        let filterItem = KnowledgeItem(
            categoryID: filtration,
            title: "Pool filter manual",
            details: "Manufacturer manual for the sand filter and multiport valve.",
            tags: ["pool", "filter", "manual"],
            provenance: .manufacturerDocument,
            createdAt: now.addingTimeInterval(-10 * day),
            updatedAt: now.addingTimeInterval(-10 * day)
        )
        let panelItem = KnowledgeItem(
            categoryID: panel,
            title: "Breaker panel labels",
            details: "Photo of the main panel with labelled breakers.",
            tags: ["breakers", "panel"],
            provenance: .userNote,
            createdAt: now.addingTimeInterval(-4 * 3600),
            updatedAt: now.addingTimeInterval(-4 * 3600)
        )

        let fillTanks = Instruction(
            categoryID: tanks,
            relatedItemIDs: [valvesItem.id],
            title: "Filling the storage tanks from city water",
            summary: "Switch the supply so the tanks fill from the city line.",
            preconditions: ["City water supply is available."],
            steps: [
                InstructionStep(text: "Check the current water supply configuration."),
                InstructionStep(text: "Locate the city water input valve."),
                InstructionStep(text: "Check the tank filling valve."),
                InstructionStep(text: "Follow the documented valve configuration."),
                InstructionStep(text: "Verify that the tanks are filling correctly."),
            ],
            warnings: ["Do not operate valves that are not documented in the valve photo."],
            expectedResult: "Tanks are filling; house supply is unaffected.",
            provenance: .userNote,
            isFavorite: true,
            usageCount: 5
        )
        let poolStart = Instruction(
            categoryID: filtration,
            relatedItemIDs: [filterItem.id],
            title: "Starting pool filtration",
            summary: "Start the pump and verify circulation.",
            steps: [
                InstructionStep(text: "Check that the water level is sufficient."),
                InstructionStep(text: "Verify the documented valve positions."),
                InstructionStep(text: "Prepare the pump according to its manual."),
                InstructionStep(text: "Start the pump using the documented procedure."),
                InstructionStep(text: "Check for normal water circulation."),
            ],
            warnings: ["Never run the pump dry."],
            expectedResult: "Water returns to the pool through the inlets.",
            provenance: .userNote,
            usageCount: 3
        )

        return ([boilerItem, valvesItem, shutoffItem, filterItem, panelItem], [fillTanks, poolStart])
    }
}
