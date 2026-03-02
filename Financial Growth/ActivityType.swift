//
//  ActivityType.swift
//  Financial Growth
//

import Foundation
import SwiftUI

struct ActivityType: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let symbolName: String
    let colorName: String

    static let systemTypes: [ActivityType] = [
        ActivityType(id: "Coaching", displayName: "Coaching", symbolName: "person.fill", colorName: "blue"),
        ActivityType(id: "Workshop", displayName: "Workshop", symbolName: "person.3.fill", colorName: "purple"),
        ActivityType(id: "Team Coaching", displayName: "Team Coaching", symbolName: "person.2.fill", colorName: "green"),
        ActivityType(id: "Altele", displayName: "Altele", symbolName: "ellipsis.circle.fill", colorName: "orange")
    ]

    static func all(custom: [ActivityType] = []) -> [ActivityType] {
        return systemTypes + custom
    }

    init(id: String, displayName: String, symbolName: String, colorName: String) {
        self.id = id
        self.displayName = displayName
        self.symbolName = symbolName
        self.colorName = colorName
    }
    
    // For backward compatibility with enum rawValue
    init?(rawValue: String) {
        if let system = ActivityType.systemTypes.first(where: { $0.id == rawValue }) {
            self = system
        } else {
            // For custom types, we'd need more info, but for now we fallback to Altele if not found
            // In a real app we might store these in a more robust way
            self.id = rawValue
            self.displayName = rawValue
            self.symbolName = "tag.fill"
            self.colorName = "blue"
        }
    }
    
    var rawValue: String { id }

    static func resolve(id: String?, custom: [ActivityType] = []) -> ActivityType {
        guard let id = id else { return systemTypes.last! }
        let allTypes = all(custom: custom)
        return allTypes.first(where: { $0.id == id }) ?? ActivityType(rawValue: id) ?? systemTypes.last!
    }
}
