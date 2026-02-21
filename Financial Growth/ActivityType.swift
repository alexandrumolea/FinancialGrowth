//
//  ActivityType.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import Foundation

enum ActivityType: String, CaseIterable, Identifiable {
    case coaching = "Coaching"
    case workshop = "Workshop"
    case teamCoaching = "Team Coaching"
    case others = "Altele"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var symbolName: String {
        switch self {
        case .coaching:    return "person.fill"
        case .workshop:    return "person.3.fill"
        case .teamCoaching: return "person.2.fill"
        case .others:      return "ellipsis.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .coaching:     return "blue"
        case .workshop:     return "purple"
        case .teamCoaching: return "green"
        case .others:       return "orange"
        }
    }
}
