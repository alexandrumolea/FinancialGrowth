//
//  ActivitiesListView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI
import CoreData

struct ActivitiesListView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.startDate, ascending: false)],
        animation: .default
    )
    private var activities: FetchedResults<Activity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProfileSettings.id, ascending: true)],
        animation: .default
    )
    private var settingsList: FetchedResults<ProfileSettings>

    @State private var showingAddActivity = false
    @State private var selectedFilter: ActivityFilter = .all

    enum ActivityFilter: String, CaseIterable, Identifiable {
        case all = "Toate"
        case upcoming = "Urmează"
        var id: String { self.rawValue }
    }

    private var customActivityTypes: [ActivityType] {
        guard let json = settingsList.first?.customActivityTypesJSON,
              let data = json.data(using: .utf8),
              let types = try? JSONDecoder().decode([ActivityType].self, from: data) else {
            return []
        }
        return types
    }

    struct ActivityGroup: Identifiable {
        let id: Date
        let title: String
        let activities: [Activity]
    }

    private var groupedActivities: [ActivityGroup] {
        let now = Date()
        
        let filtered: [Activity]
        let ascending: Bool
        switch selectedFilter {
        case .all:
            filtered = Array(activities)
            ascending = false
        case .upcoming:
            filtered = activities
                .filter { ($0.startDate ?? Date()) >= Calendar.current.startOfDay(for: now) }
                .sorted { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }
            ascending = true
        }
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Luni
        
        let grouped = Dictionary(grouping: filtered) { activity -> Date in
            let date = activity.startDate ?? Date()
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: components) ?? date
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ro_RO")
        
        return grouped.map { (startOfWeek, acts) in
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            let title = "\(startString) - \(endString)"
            
            let sortedActs = acts.sorted { 
                if ascending {
                    return ($0.startDate ?? Date()) < ($1.startDate ?? Date())
                } else {
                    return ($0.startDate ?? Date()) > ($1.startDate ?? Date())
                }
            }
            
            return ActivityGroup(id: startOfWeek, title: title, activities: sortedActs)
        }
        .sorted {
            if ascending {
                return $0.id < $1.id
            } else {
                return $0.id > $1.id
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            Picker("Filtru", selection: $selectedFilter) {
                                ForEach(ActivityFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                        if groupedActivities.isEmpty {
                            Section {
                                Text("Nicio activitate în această categorie")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(groupedActivities) { group in
                                Section(header: Text(group.title)) {
                                    ForEach(group.activities) { activity in
                                        NavigationLink {
                                            AddEditActivityView(activity: activity)
                                        } label: {
                                            ActivityRowView(activity: activity)
                                        }
                                    }
                                    .onDelete { offsets in
                                        deleteActivities(at: offsets, from: group)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Activități")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddEditActivityView()
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Nicio activitate")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Apasă + pentru a adăuga\nprima activitate")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Delete
    private func deleteActivities(at offsets: IndexSet, from group: ActivityGroup) {
        for index in offsets {
            let activity = group.activities[index]
            viewContext.delete(activity)
        }
        PersistenceController.shared.save()
    }
}

#Preview {
    ActivitiesListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
