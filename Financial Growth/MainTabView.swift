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
            ActivitiesListView()
                .tabItem {
                    Label("Activități", systemImage: "list.bullet.clipboard")
                }

            ClientsListView()
                .tabItem {
                    Label("Clienți", systemImage: "person.2")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ReportsView()
                .tabItem {
                    Label("Rapoarte", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
