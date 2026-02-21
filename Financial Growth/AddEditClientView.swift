//
//  AddEditClientView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI

struct AddEditClientView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var client: Client?

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""

    private var isEditing: Bool { client != nil }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Informații client") {
                    TextField("Nume *", text: $name)
                        .textContentType(.organizationName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
            }
            .navigationTitle(isEditing ? "Editare client" : "Client nou")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează") {
                        saveClient()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExistingClient)
        }
    }

    private func loadExistingClient() {
        guard let c = client else { return }
        name = c.name ?? ""
        email = c.email ?? ""
        phone = c.phone ?? ""
    }

    private func saveClient() {
        let c = client ?? Client(context: viewContext)
        c.id = c.id ?? UUID()
        c.name = name.trimmingCharacters(in: .whitespaces)
        c.email = email.isEmpty ? nil : email
        c.phone = phone.isEmpty ? nil : phone
        c.createdAt = c.createdAt ?? Date()
        PersistenceController.shared.save()
    }
}

#Preview {
    AddEditClientView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
