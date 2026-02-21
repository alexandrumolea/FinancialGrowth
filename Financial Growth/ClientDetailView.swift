//
//  ClientDetailView.swift
//  Financial Growth
//
//  Created by Antigravity on 19.02.2026.
//

import SwiftUI
import CoreData

struct ClientDetailView: View {
    @ObservedObject var client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditClient = false
    
    // Sort activities by date descending
    private var sortedActivities: [Activity] {
        let activitiesSet = client.activities as? Set<Activity> ?? []
        return activitiesSet.sorted { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) }
    }
    
    private var totalAmount: Double {
        sortedActivities.reduce(0) { $0 + $1.totalAmount }
    }
    
    private var totalHours: Double {
        sortedActivities.reduce(0) { $0 + $1.hours }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Info
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Text(String(client.name?.prefix(2) ?? "").uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text(client.name ?? "Fără nume")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let email = client.email, !email.isEmpty {
                            Label(email, systemImage: "envelope")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let phone = client.phone, !phone.isEmpty {
                            Label(phone, systemImage: "phone")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                // Metrics Cards
                HStack(spacing: 16) {
                    MetricCard(title: "Ore Totale", value: totalHours.hoursString, icon: "clock.fill", color: .orange)
                    MetricCard(title: "Total Încasat", value: totalAmount.currencyString, icon: "eurosign.circle.fill", color: .green)
                }
                .padding(.horizontal)
                
                // Activities History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Istoric Activități")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if sortedActivities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("Nicio activitate înregistrată")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(sortedActivities) { activity in
                                NavigationLink {
                                    AddEditActivityView(activity: activity)
                                } label: {
                                    ActivityRowView(activity: activity)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                
                                if activity != sortedActivities.last {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalii Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !sortedActivities.isEmpty {
                    let label = "Activitate \(client.name ?? "")"
                    let pdfData = generatePDFData(label: label)
                    
                    if let data = pdfData {
                        ShareLink(
                            item: PDFExportDocument(data: data, label: label),
                            preview: SharePreview("Raport \(client.name ?? "")", image: Image(systemName: "doc.richtext.fill"))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editează") {
                    showingEditClient = true
                }
            }
        }
        .sheet(isPresented: $showingEditClient) {
            AddEditClientView(client: client)
        }
    }
    
    @MainActor
    private func generatePDFData(label: String) -> Data? {
        let pdfView = PDFReportView(
            periodLabel: label,
            activities: sortedActivities,
            totalAmount: totalAmount,
            totalHours: totalHours
        )
        
        let renderer = ImageRenderer(content: pdfView)
        renderer.scale = 3.0
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        
        var generatedData: Data?
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            
            generatedData = try? Data(contentsOf: url)
        }
        
        try? FileManager.default.removeItem(at: url)
        
        return generatedData
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
