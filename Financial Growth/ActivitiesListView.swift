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

    @State private var showingAddActivity = false

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(activities) { activity in
                            NavigationLink {
                                AddEditActivityView(activity: activity)
                            } label: {
                                ActivityRowView(activity: activity)
                            }
                        }
                        .onDelete(perform: deleteActivities)
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
    private func deleteActivities(at offsets: IndexSet) {
        offsets.map { activities[$0] }.forEach(viewContext.delete)
        PersistenceController.shared.save()
    }
}

#Preview {
    ActivitiesListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
