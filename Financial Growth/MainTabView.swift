//
//  MainTabView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ClientsListView()
                .tabItem {
                    Label("Clienți", systemImage: "person.2")
                }

            ReportsView()
                .tabItem {
                    Label("Rapoarte", systemImage: "chart.bar")
                }

            ActivitiesListView()
                .tabItem {
                    Label("Activități", systemImage: "list.bullet.clipboard")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
