//
//  TwoWeekGridView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 06.03.2026.
//

import SwiftUI
import CoreData

// MARK: - Main 2-Week Grid

struct TwoWeekGridView: View {
    let activities: FetchedResults<Activity>
    let customActivityTypes: [ActivityType]
    
    // Base date is the start of the first week shown (Monday)
    @State private var baseDate: Date = Date().startOfWeek
    
    private let calendar = Calendar.current

    /// 14 zile (2 săptămâni) pornind de la baseDate
    private var days: [Date] {
        (0..<14).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: baseDate)
        }
    }

    /// Împarte cele 14 zile în 2 rânduri de câte 7
    private var weeks: [[Date]] {
        days.chunked(into: 7)
    }

    // Dynamic day labels based on locale
    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ro_RO")
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["D", "L", "M", "M", "J", "V", "S"]
        // Reorder for Monday start: [1, 2, 3, 4, 5, 6, 0]
        return [symbols[1], symbols[2], symbols[3], symbols[4], symbols[5], symbols[6], symbols[0]]
    }
    
    private var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ro_RO")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: baseDate).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Navigation Header
            HStack {
                Text(monthYearLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { moveWeek(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { moveWeek(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 4)

            // Weekday labels
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid rows
            VStack(spacing: 4) {
                ForEach(weeks, id: \.self) { week in
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(week, id: \.self) { day in
                            DayCellView(
                                day: day,
                                activities: activitiesFor(day: day),
                                customTypes: customActivityTypes
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    private func moveWeek(by offset: Int) {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: offset, to: baseDate) {
            withAnimation {
                baseDate = newDate
            }
        }
    }

    private func activitiesFor(day: Date) -> [Activity] {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }
        return activities.filter { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let actStart = calendar.startOfDay(for: start)
            let actEnd = calendar.startOfDay(for: end)
            
            // Overlaps logic
            return (actStart <= dayStart && actEnd >= dayStart) || (actStart >= dayStart && actStart < dayEnd)
        }
    }
}

// MARK: - Day Cell

private struct DayCellView: View {
    let day: Date
    let activities: [Activity]
    let customTypes: [ActivityType]

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: day)
        // 1 = Sunday, 7 = Saturday in default Gregorian
        return weekday == 1 || weekday == 7
    }

    private var dayNumber: String {
        let n = Calendar.current.component(.day, from: day)
        return "\(n)"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Day Number
            Text(dayNumber)
                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? .white : (isWeekend ? .secondary : .primary))
                .frame(width: 26, height: 26)
                .background(
                    ZStack {
                        if isToday {
                            Circle().fill(Color.accentColor)
                        }
                    }
                )

            // Activity Chips
            VStack(spacing: 3) {
                ForEach(activities.prefix(3)) { activity in
                    ActivityChip(activity: activity, customTypes: customTypes)
                }
                
                if activities.count > 3 {
                    Text("+\(activities.count - 3)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 40, alignment: .top)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isWeekend
                      ? Color(.systemGray6).opacity(0.8)
                      : Color(.systemBackground))
        )
    }
}

// MARK: - Activity Chip

private struct ActivityChip: View {
    @ObservedObject var activity: Activity
    let customTypes: [ActivityType]

    private var type: ActivityType {
        ActivityType.resolve(id: activity.activityType, custom: customTypes)
    }

    private var label: String {
        if let name = activity.client?.name, !name.isEmpty {
            return name
        }
        return type.displayName
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: type.symbolName)
                .font(.system(size: 8))
                .foregroundStyle(type.color)
            
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(type.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(type.color.opacity(0.2))
        )
    }
}
