//
//  CalendarView.swift
//  Financial Growth
//
//  Created by Antigravity on 20.02.2026.
//

import SwiftUI
import CoreData
import EventKit

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
    @State private var appleEvents: [EKEvent] = []
    
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
                    monthHeader
                    
                    calendarGrid
                    
                    dayDetailSection
                }
                .padding(.vertical)
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
                refreshAppleEvents()
            }
            .onChange(of: selectedDate) { _, _ in
                refreshAppleEvents()
            }
        }
    }
    
    // MARK: - View Sections
    private var monthHeader: some View {
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
    }
    
    private var calendarGrid: some View {
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
    }
    
    private enum TimelineItemType {
        case activity(Activity)
        case appleEvent(EKEvent)
        case free(Date, Date)
    }

    private struct TimelineItem: Identifiable {
        let id = UUID()
        let type: TimelineItemType
        let startDate: Date
        let endDate: Date
        
        var isFree: Bool {
            if case .free = type { return true }
            return false
        }
    }

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Add Apple Events ONLY
        for event in appleEvents {
            items.append(TimelineItem(type: .appleEvent(event), startDate: event.startDate, endDate: event.endDate))
        }
        
        // Sort by start date
        let sortedItems = items.sorted { $0.startDate < $1.startDate }
        
        if sortedItems.isEmpty { return [] }
        
        var finalItems: [TimelineItem] = []
        
        // Add items and calculate gaps
        for i in 0..<sortedItems.count {
            let current = sortedItems[i]
            
            // If there's a previous item, check for a gap
            if let last = finalItems.last {
                if current.startDate > last.endDate.addingTimeInterval(60) { // More than 1 minute gap
                    finalItems.append(TimelineItem(type: .free(last.endDate, current.startDate), startDate: last.endDate, endDate: current.startDate))
                }
            }
            
            finalItems.append(current)
        }
        
        return finalItems
    }
    
    private var dayDetailSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section 1: App Activities (My Sessions)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sesiunile Mele")
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
                    Text("Nicio activitate înregistrată")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 12) {
                        ForEach(activitiesForSelectedDate) { activity in
                            NavigationLink {
                                AddEditActivityView(activity: activity)
                            } label: {
                                HStack(spacing: 0) {
                                    ActivityRowView(activity: activity)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.tertiary)
                                        .padding(.leading, 8)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Section 2: Availability (Apple Calendar)
            if !appleEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Disponibilitate (Calendar Apple)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(timelineItems) { item in
                            timelineRow(for: item)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 {
                        // Swipe Left -> Next Day
                        selectNextDay()
                    } else if value.translation.width > 50 {
                        // Swipe Right -> Previous Day
                        selectPreviousDay()
                    }
                }
        )
    }
    
    private func selectNextDay() {
        if let next = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            withAnimation {
                selectedDate = next
                if !calendar.isDate(next, equalTo: currentMonth, toGranularity: .month) {
                    currentMonth = next.startOfMonth
                }
            }
        }
    }
    
    private func selectPreviousDay() {
        if let prev = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            withAnimation {
                selectedDate = prev
                if !calendar.isDate(prev, equalTo: currentMonth, toGranularity: .month) {
                    currentMonth = prev.startOfMonth
                }
            }
        }
    }
    
    @ViewBuilder
    private func timelineRow(for item: TimelineItem) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Time Column
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.startDate.timeOnlyFormatted)
                    .font(.caption.bold())
                Text(item.endDate.timeOnlyFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 45)
            
            // Indicator and Content
            VStack(spacing: 0) {
                switch item.type {
                case .activity(let activity):
                    NavigationLink {
                        AddEditActivityView(activity: activity)
                    } label: {
                        HStack {
                            Capsule()
                                .fill(ActivityType(rawValue: activity.activityType ?? "")?.color ?? .gray)
                                .frame(width: 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.client?.name ?? "Client Necunoscut")
                                    .font(.subheadline.bold())
                                if let notes = activity.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color(.tertiarySystemGroupedBackground).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                case .appleEvent(let event):
                    HStack {
                        Capsule()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            Text("Calendar Apple")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground).opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                case .free(let start, let end):
                    HStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            .frame(width: 6, height: 6)
                        
                        Text("Liber (\(formatDuration(from: start, to: end)))")
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        
        if item.id != timelineItems.last?.id && !item.isFree {
            Divider().padding(.leading, 72)
        }
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let diff = Int(end.timeIntervalSince(start))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
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
    
    private func refreshAppleEvents() {
        Task {
            let granted = await CalendarService.shared.requestAccess()
            if granted {
                let start = calendar.startOfDay(for: selectedDate)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                appleEvents = CalendarService.shared.fetchEvents(from: start, to: end)
            }
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
        
        let types = Set(dayActivities.compactMap { ActivityType(rawValue: $0.activityType ?? "") } )
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
