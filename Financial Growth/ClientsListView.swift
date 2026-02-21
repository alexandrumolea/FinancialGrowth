//
//  ClientsListView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI
import CoreData

struct ClientsListView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default
    )
    private var clients: FetchedResults<Client>

    @State private var showingAddClient = false

    var body: some View {
        NavigationStack {
            Group {
                if clients.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(clients) { client in
                            NavigationLink {
                                ClientDetailView(client: client)
                            } label: {
                                ClientRowView(client: client)
                            }
                        }
                        .onDelete(perform: deleteClients)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Clienți")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddClient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddEditClientView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Niciun client")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Apasă + pentru a adăuga\nprimul client")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteClients(at offsets: IndexSet) {
        offsets.map { clients[$0] }.forEach(viewContext.delete)
        PersistenceController.shared.save()
    }
}

#Preview {
    ClientsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
