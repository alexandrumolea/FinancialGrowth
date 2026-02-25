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
    
    @State private var selectedDate = Date().startOfDay
    @State private var currentMonth = Date().startOfMonth
    @State private var showingAddActivity = false
    
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday (Standard in Romania)
        return cal
    }()
    
    private var activitiesForSelectedDate: [Activity] {
        allActivities.filter { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: max(start, end))
            let checkDate = calendar.startOfDay(for: selectedDate)
            return checkDate >= startOfDay && checkDate <= endOfDay
        }
    }
    
    private let weekdayHeaders = ["L", "M", "M", "J", "V", "S", "D"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month Navigation & Title
                    HStack {
                        VStack(alignment: .leading) {
                            Text(currentMonth.monthYearString)
                                .font(.title2.bold())
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: { changeMonth(by: -1) }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button(action: { changeMonth(by: 1) }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Calendar Grid Section
                    VStack(spacing: 8) {
                        // Week Headers
                        HStack(spacing: 0) {
                            ForEach(weekdayHeaders, id: \.self) { day in
                                Text(day)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        let daysInMonth = daysInCurrentMonth()
                        let firstDayOffset = firstWeekdayOffset()
                        let totalCells = daysInMonth + firstDayOffset
                        let rows = Int(ceil(Double(totalCells) / 7.0))
                        
                        VStack(spacing: 0) {
                            ForEach(0..<rows, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<7, id: \.self) { column in
                                        let index = row * 7 + column
                                        let dayValue = index - firstDayOffset + 1
                                        
                                        if dayValue >= 1 && dayValue <= daysInMonth {
                                            let date = dateForDay(dayValue)
                                            DayView(
                                                day: dayValue,
                                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                                isToday: calendar.isDateInToday(date),
                                                hasActivities: hasActivities(on: date),
                                                activityColors: colorsForActivities(on: date)
                                            )
                                            .frame(maxWidth: .infinity)
                                            .onTapGesture {
                                                selectedDate = date
                                            }
                                        } else {
                                            Color.clear
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 50)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Selected Date Activities
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedDate.mediumFormatted)
                                .font(.headline)
                            Spacer()
                            if !activitiesForSelectedDate.isEmpty {
                                Text("\(activitiesForSelectedDate.count) sesiuni")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if activitiesForSelectedDate.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(.quaternary)
                                Text("Nicio activitate programată")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(activitiesForSelectedDate) { activity in
                                    NavigationLink {
                                        AddEditActivityView(activity: activity)
                                    } label: {
                                        ActivityRowView(activity: activity)
                                            .padding()
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddEditActivityView(initialDate: selectedDate)
            }
            .onAppear {
                currentMonth = currentMonth.startOfMonth
            }
        }
    }
    
    // MARK: - Helpers
    private func daysInCurrentMonth() -> Int {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        return range.count
    }
    
    private func firstWeekdayOffset() -> Int {
        // weekday returns 1 for Sun, 2 for Mon, ...
        let weekday = calendar.component(.weekday, from: currentMonth)
        // With firstWeekday = 2 (Mon):
        // Mon(2) -> 0, Tue(3) -> 1, ... Sun(1) -> 6
        return (weekday + 5) % 7
    }
    
    private func dateForDay(_ day: Int) -> Date {
        var components = calendar.dateComponents([.year, .month], from: currentMonth)
        components.day = day
        return calendar.date(from: components) ?? Date()
    }
    
    private func changeMonth(by amount: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: amount, to: currentMonth) {
            currentMonth = newMonth.startOfMonth
        }
    }
    
    private func hasActivities(on date: Date) -> Bool {
        let checkDate = calendar.startOfDay(for: date)
        return allActivities.contains { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: max(start, end))
            return checkDate >= startOfDay && checkDate <= endOfDay
        }
    }
    
    private func colorsForActivities(on date: Date) -> [Color] {
        let checkDate = calendar.startOfDay(for: date)
        let dayActivities = allActivities.filter { activity in
            guard let start = activity.startDate, let end = activity.endDate else { return false }
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: max(start, end))
            return checkDate >= startOfDay && checkDate <= endOfDay
        }
        
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
