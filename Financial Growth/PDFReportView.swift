//
//  PDFReportView.swift
//  Financial Growth
//
//  Created by Antigravity on 19.02.2026.
//

import SwiftUI

struct PDFReportView: View {
    let periodLabel: String
    let activities: [Activity]
    let totalAmount: Double
    let totalHours: Double
    
    // Pagination properties
    let pageNumber: Int
    let totalPages: Int
    let isFirstPage: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isFirstPage {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Raport Activitate")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(periodLabel)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // Summary
                HStack(spacing: 40) {
                    SummaryItem(title: "Total Încasat", value: totalAmount.currencyString, color: .green)
                    SummaryItem(title: "Total Ore", value: totalHours.hoursString, color: .orange)
                    SummaryItem(title: "Sesiuni", value: "\(activities.count)", color: .blue)
                }
                .padding(.vertical, 10)
                
                Divider()
            } else {
                // Secondary Page Header
                HStack {
                    Text("Raport Activitate - Continuare (\(periodLabel))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Pagina \(pageNumber) din \(totalPages)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 5)
                
                Divider()
            }
            
            // Activities Table Header
            HStack {
                Text("Dată").frame(width: 70, alignment: .leading)
                Text("Client").frame(width: 110, alignment: .leading)
                Text("Tip").frame(width: 90, alignment: .leading)
                Text("Ore").frame(width: 40, alignment: .trailing)
                Text("Statut").frame(width: 60, alignment: .center)
                Spacer()
                Text("Sumă").frame(width: 70, alignment: .trailing)
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            
            // Activities List (Paginated)
            VStack(spacing: 0) {
                ForEach(activities) { activity in
                    ActivityRow(activity: activity)
                    Divider()
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("Pagina \(pageNumber) / \(totalPages)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Generat la \(Date().mediumFormatted)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4 at 72dpi
        .background(Color.white)
    }
}

private struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
}

private struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(activity.startDate?.shortFormatted ?? "")
                    .frame(width: 70, alignment: .leading)
                
                Text(activity.client?.name ?? "Fără client")
                    .frame(width: 110, alignment: .leading)
                    .lineLimit(1)
                
                Text(ActivityType(rawValue: activity.activityType ?? "")?.displayName ?? "Altele")
                    .frame(width: 90, alignment: .leading)
                
                Text(String(format: "%.1f", activity.hours))
                    .frame(width: 40, alignment: .trailing)
                
                Text(activity.isInvoiced != 0 ? "Facturat" : "Pendent")
                    .frame(width: 60, alignment: .center)
                    .foregroundStyle(activity.isInvoiced != 0 ? .green : .orange)
                    .font(.system(size: 8, weight: .bold))
                
                Spacer()
                
                Text(activity.totalAmount.currencyString)
                    .frame(width: 70, alignment: .trailing)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 11))
            
            if let notes = activity.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 74) // Adjusted for new widths
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
