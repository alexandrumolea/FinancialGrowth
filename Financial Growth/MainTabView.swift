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

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProfileSettings.id, ascending: true)],
        animation: .default
    )
    private var settingsList: FetchedResults<ProfileSettings>
    
    @State private var showingAddType = false
    @State private var newTypeName = ""
    @State private var selectedColor = "blue"
    
    private var settings: ProfileSettings? {
        settingsList.first
    }
    
    let availableColors = ["blue", "purple", "green", "orange", "red", "pink", "teal", "indigo"]
    
    var customTypes: [ActivityType] {
        guard let json = settings?.customActivityTypesJSON,
              let data = json.data(using: .utf8),
              let types = try? JSONDecoder().decode([ActivityType].self, from: data) else {
            return []
        }
        return types
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let settings = settings {
                    Section(header: Text("Obiective Ore")) {
                        HStack {
                            Text("Obiectiv săptămânal")
                            Spacer()
                            Stepper(value: Binding(
                                get: { settings.weeklyHoursGoal },
                                set: { newValue in
                                    settings.weeklyHoursGoal = newValue
                                    save()
                                }
                            ), in: 1...168, step: 1) {
                                Text("\(Int(settings.weeklyHoursGoal)) ore")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Text("Obiectiv lunar")
                            Spacer()
                            Stepper(value: Binding(
                                get: { settings.monthlyHoursGoal },
                                set: { newValue in
                                    settings.monthlyHoursGoal = newValue
                                    save()
                                }
                            ), in: 1...744, step: 1) {
                                Text("\(Int(settings.monthlyHoursGoal)) ore")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("Se încarcă setările...")
                            .onAppear {
                                _ = PersistenceController.shared.getOrCreateSettings(in: viewContext)
                            }
                    }
                }
                
                Section(header: Text("Tipuri de Activități Personalizate")) {
                    ForEach(customTypes) { type in
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(type.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: type.symbolName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(type.color)
                            }
                            Text(type.displayName)
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteCustomType)
                    
                    Button(action: { showingAddType = true }) {
                        Label("Adaugă tip nou", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Profil")
            .sheet(isPresented: $showingAddType) {
                NavigationStack {
                    Form {
                        Section("Detalii") {
                            TextField("Nume tip activitate", text: $newTypeName)
                            
                            Picker("Culoare", selection: $selectedColor) {
                                ForEach(availableColors, id: \.self) { color in
                                    HStack {
                                        Circle().fill(colorFromName(color)).frame(width: 20, height: 20)
                                        Text(color.capitalized)
                                    }.tag(color)
                                }
                            }
                        }
                    }
                    .navigationTitle("Tip Nou")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Anulează") { showingAddType = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Adaugă") {
                                addCustomType()
                                showingAddType = false
                            }
                            .disabled(newTypeName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func addCustomType() {
        var types = customTypes
        let newType = ActivityType(
            id: newTypeName,
            displayName: newTypeName,
            symbolName: "tag.fill",
            colorName: selectedColor
        )
        types.append(newType)
        saveCustomTypes(types)
        newTypeName = ""
    }
    
    private func deleteCustomType(at offsets: IndexSet) {
        var types = customTypes
        types.remove(atOffsets: offsets)
        saveCustomTypes(types)
    }
    
    private func saveCustomTypes(_ types: [ActivityType]) {
        if let data = try? JSONEncoder().encode(types),
           let json = String(data: data, encoding: .utf8) {
            settings?.customActivityTypesJSON = json
            save()
        }
    }
    
    private func save() {
        try? viewContext.save()
    }
    
    private func colorFromName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return Color(red: 0.2, green: 0.7, blue: 0.4)
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }
}
