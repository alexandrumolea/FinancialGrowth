//
//  ContentView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
