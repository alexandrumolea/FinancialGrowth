//
//  AddEditActivityView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI
import CoreData
import EventKit

struct AddEditActivityView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // Existing activity to edit (nil = new)
    var activity: Activity?

    // MARK: - Form state
    @State private var selectedType: ActivityType = .coaching
    @State private var selectedClient: Client?
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hoursText = ""
    @State private var costPerHourText = ""
    @State private var notes = ""
    @State private var isInvoiced = false
    @State private var showingAddClient = false
    
    // Calendar integration
    @State private var eventToEdit: EventWrapper?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .none
    )
    private var clients: FetchedResults<Client>

    // MARK: - Computed
    private var computedTotal: Double {
        let h = Double(hoursText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let c = Double(costPerHourText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return h * c
    }

    private var isEditing: Bool { activity != nil }

    private var canSave: Bool {
        !hoursText.isEmpty && !costPerHourText.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Activity type
                Section("Tip activitate") {
                    Picker("Tip", selection: $selectedType) {
                        ForEach(ActivityType.allCases) { type in
                            Label(type.displayName, systemImage: type.symbolName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Client
                Section("Client") {
                    if clients.isEmpty {
                        Button("Adaugă un client...") {
                            showingAddClient = true
                        }
                    } else {
                        Picker("Client", selection: $selectedClient) {
                            Text("Fără client").tag(nil as Client?)
                            ForEach(clients) { client in
                                Text(client.name ?? "").tag(client as Client?)
                            }
                        }
                        Button("Client nou...") {
                            showingAddClient = true
                        }
                        .foregroundStyle(.blue)
                    }
                }

                // Dates
                Section("Perioadă") {
                    DatePicker("Data start", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, newValue in
                            if endDate < newValue {
                                endDate = newValue
                            }
                        }
                    DatePicker("Data end", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                // Hours & Rate
                Section("Ore & Cost") {
                    HStack {
                        Text("Număr de ore")
                        Spacer()
                        TextField("ex: 3", text: $hoursText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Cost per oră")
                        Spacer()
                        TextField("ex: 150", text: $costPerHourText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(computedTotal.currencyString)
                            .fontWeight(.semibold)
                            .foregroundStyle(computedTotal > 0 ? .green : .secondary)
                    }
                }

                // Notes
                Section("Notițe (opțional)") {
                    TextField("Observații despre sesiune...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Facturat", isOn: $isInvoiced)
                        .tint(.green)
                }

                Section {
                    Button {
                        Task {
                            await prepareCalendarEvent()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Creează eveniment în Calendar")
                        }
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle(isEditing ? "Editare activitate" : "Activitate nouă")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează") {
                        saveActivity()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddEditClientView()
            }
            .sheet(item: $eventToEdit) { wrapper in
                EKEventEditView(event: wrapper.event)
            }
            .onAppear(perform: loadExistingActivity)
    }
    }

    private func prepareCalendarEvent() async {
        let granted = await CalendarService.shared.requestAccess()
        guard granted else { return }
        
        let title = "\(selectedType.displayName) Session"
        let event = CalendarService.shared.createPlaceholderEvent(title: title, date: startDate)
        
        eventToEdit = EventWrapper(event: event)
    }

    // MARK: - Load existing
    private func loadExistingActivity() {
        guard let act = activity else { return }
        selectedType = ActivityType(rawValue: act.activityType ?? "") ?? .coaching
        selectedClient = act.client
        startDate = act.startDate ?? Date()
        endDate = act.endDate ?? Date()
        hoursText = act.hours == 0 ? "" : String(act.hours)
        costPerHourText = act.costPerHour == 0 ? "" : String(act.costPerHour)
        notes = act.notes ?? ""
        isInvoiced = act.isInvoiced != 0
    }

    // MARK: - Save
    private func saveActivity() {
        let act = activity ?? Activity(context: viewContext)
        act.id = act.id ?? UUID()
        act.activityType = selectedType.rawValue
        act.client = selectedClient
        act.startDate = startDate
        // Safety check: ensure endDate is not before startDate
        act.endDate = max(startDate, endDate)
        act.hours = Double(hoursText.replacingOccurrences(of: ",", with: ".")) ?? 0
        act.costPerHour = Double(costPerHourText.replacingOccurrences(of: ",", with: ".")) ?? 0
        act.totalAmount = computedTotal
        act.notes = notes.isEmpty ? nil : notes
        act.isInvoiced = isInvoiced ? 1 : 0
        act.createdAt = act.createdAt ?? Date()
        PersistenceController.shared.save()
    }
}

#Preview {
    AddEditActivityView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
