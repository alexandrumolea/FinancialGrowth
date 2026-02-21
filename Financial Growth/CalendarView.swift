//
//  CalendarView.swift
//  Financial Growth
//
//  Created by Antigravity on 20.02.2026.
//

import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.startDate, ascending: true)],
        animation: .default
    )
    private var allActivities: FetchedResults<Activity>
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    
    private var activitiesForSelectedDate: [Activity] {
        allActivities.filter { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: max(start, end)) // Use max for robustness
            let checkDate = calendar.startOfDay(for: selectedDate)
            return checkDate >= startOfDay && checkDate <= endOfDay
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar Header
                HStack {
                    Text(currentMonth.monthYearString)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                        }
                        
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                
                // Days of week
                HStack {
                    let days = ["Lu", "Ma", "Mi", "Jo", "Vi", "Sâ", "Du"]
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Calendar Grid
                let daysInMonth = daysInCurrentMonth()
                let firstDayOffset = firstWeekdayOffset()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    // Padding for first week
                    ForEach(0..<firstDayOffset, id: \.self) { _ in
                        Text("")
                            .frame(height: 40)
                    }
                    
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let date = dateForDay(day)
                        DayView(
                            day: day,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasActivities: hasActivities(on: date),
                            activityColors: colorsForActivities(on: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Divider()
                
                // Activities for selected day
                List {
                    Section {
                        if activitiesForSelectedDate.isEmpty {
                            ContentUnavailableView(
                                "Nicio activitate",
                                systemImage: "calendar.badge.exclamationmark",
                                description: Text("Nu ai nicio sesiune programată pentru această zi.")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(activitiesForSelectedDate) { activity in
                                NavigationLink {
                                    AddEditActivityView(activity: activity)
                                } label: {
                                    ActivityRowView(activity: activity)
                                }
                            }
                        }
                    } header: {
                        Text(selectedDate.mediumFormatted)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Calendar")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Helpers
    private func daysInCurrentMonth() -> Int {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        return range.count
    }
    
    private func firstWeekdayOffset() -> Int {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let firstOfMonth = calendar.date(from: components)!
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        // Convert to Monday start (1=Mon, 7=Sun)
        let offset = (weekday + 5) % 7
        return offset
    }
    
    private func dateForDay(_ day: Int) -> Date {
        var components = calendar.dateComponents([.year, .month], from: currentMonth)
        components.day = day
        return calendar.date(from: components)!
    }
    
    private func changeMonth(by amount: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: amount, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func hasActivities(on date: Date) -> Bool {
        let checkDate = calendar.startOfDay(for: date)
        return allActivities.contains { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: max(start, end)) // Use max for robustness
            return checkDate >= startOfDay && checkDate <= endOfDay
        }
    }
    
    private func colorsForActivities(on date: Date) -> [Color] {
        let checkDate = calendar.startOfDay(for: date)
        let dayActivities = allActivities.filter { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: end)
            return checkDate >= startOfDay && checkDate <= endOfDay
        }
        
        // Get unique activity type colors
        let types = Set(dayActivities.compactMap { ActivityType(rawValue: $0.activityType ?? "") })
        return types.map { $0.color }
    }
}

// MARK: - Supporting Views
struct DayView: View {
    let day: Int
    let isSelected: Bool
    let isToday: Bool
    let hasActivities: Bool
    let activityColors: [Color]
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : (isToday ? .accentColor : .primary))
                .frame(width: 32, height: 32)
                .background(
                    ZStack {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        } else if isToday {
                            Circle().stroke(Color.accentColor, lineWidth: 2)
                        }
                    }
                )
            
            HStack(spacing: 3) {
                if hasActivities {
                    ForEach(activityColors.prefix(3), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                    }
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

extension Date {
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self).capitalized
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
