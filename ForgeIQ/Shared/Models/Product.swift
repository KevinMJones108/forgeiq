// ForgeIQ Product Model
// Session 12 — Product Library
// Sales reps upload product specs before calls

import Foundation

struct Product: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: String?
    let specs: [String: String] // Key-value pairs (e.g., "Horsepower": "168 HP")
    let linkedScriptId: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, category, specs
        case linkedScriptId = "linked_script_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        name: String,
        category: String? = nil,
        specs: [String: String] = [:],
        linkedScriptId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.specs = specs
        self.linkedScriptId = linkedScriptId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Example Products
extension Product {
    static let sampleExcavator = Product(
        name: "CAT 320 Excavator",
        category: "Heavy Equipment",
        specs: [
            "Horsepower": "168 HP",
            "Bucket Capacity": "1.2 cubic yards",
            "Operating Weight": "52,000 lbs",
            "Fuel Consumption": "8 gal/hr",
            "Price": "$250,000"
        ]
    )

    static let samplePump = Product(
        name: "Grundfos CR 64-5",
        category: "Pumps",
        specs: [
            "Flow Rate": "100 GPM",
            "Head": "350 ft",
            "Motor": "25 HP",
            "Material": "Stainless Steel 316",
            "Price": "$8,500"
        ]
    )

    static let samples = [sampleExcavator, samplePump]
}
