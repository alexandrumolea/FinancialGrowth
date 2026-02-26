//
//  Extensions.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import Foundation
import SwiftUI

// MARK: - Double formatting
extension Double {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }

    var hoursString: String {
        if self == floor(self) {
            return String(format: "%.0f ore", self)
        }
        return String(format: "%.1f ore", self)
    }
}

// MARK: - Date helpers
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var mediumFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var timeOnlyFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var roundedToNextHour: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        if let minute = components.minute, minute > 0 {
            components.hour = (components.hour ?? 0) + 1
        }
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? self
    }
}

// MARK: - ActivityType Color
extension ActivityType {
    var color: Color {
        switch self {
        case .coaching:     return .blue
        case .workshop:     return .purple
        case .teamCoaching: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .others:       return .orange
        }
    }
}
// MARK: - Activity CSV Export
extension Array where Element == Activity {
    func csvString(periodLabel: String) -> String {
        var csv = "Raport Activitate: \(periodLabel)\n"
        csv += "Data Start,Data End,Client,Tip Activitate,Ore,Cost/Ora,Total,Status,Notite\n"
        
        for activity in self {
            let start = activity.startDate?.mediumFormatted ?? ""
            let end = activity.endDate?.mediumFormatted ?? ""
            let client = activity.client?.name ?? "Fara client"
            let type = ActivityType(rawValue: activity.activityType ?? "")?.displayName ?? "Altele"
            let hours = String(format: "%.1f", activity.hours)
            let rate = String(format: "%.2f", activity.costPerHour)
            let total = String(format: "%.2f", activity.totalAmount)
            let status = activity.isInvoiced != 0 ? "Facturat" : "Nefacturat"
            let notes = (activity.notes ?? "").replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ",", with: ";")
            
            csv += "\(start),\(end),\"\(client)\",\(type),\(hours),\(rate),\(total),\(status),\"\(notes)\"\n"
        }
        
        return csv
    }
}
// MARK: - Array pagination
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
