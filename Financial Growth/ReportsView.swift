//
//  ReportsView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

enum ReportPeriod: String, CaseIterable, Identifiable {
    case week = "Săptămână"
    case month = "Lună"
    case custom = "Personalizat"
    var id: String { rawValue }
}

enum InvoiceFilter: String, CaseIterable, Identifiable {
    case all = "Toate"
    case invoiced = "Facturate"
    case notInvoiced = "Nefacturate"
    var id: String { rawValue }
}

struct ReportsView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.startDate, ascending: false)],
        animation: .default
    )
    private var allActivities: FetchedResults<Activity>

    @State private var selectedPeriod: ReportPeriod = .month
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd = Date()
    @State private var selectedInvoiceFilter: InvoiceFilter = .all

    // MARK: - Filtered activities
    private var filteredActivities: [Activity] {
        let (start, end) = dateRange()
        return allActivities.filter { activity in
            guard let actStart = activity.startDate else { return false }
            
            let matchesDate = actStart >= start && actStart <= end
            
            let matchesInvoiceStatus: Bool
            switch selectedInvoiceFilter {
            case .all:
                matchesInvoiceStatus = true
            case .invoiced:
                matchesInvoiceStatus = activity.isInvoiced != 0
            case .notInvoiced:
                matchesInvoiceStatus = activity.isInvoiced == 0
            }
            
            return matchesDate && matchesInvoiceStatus
        }
    }

    private var totalAmount: Double {
        filteredActivities.reduce(0) { $0 + $1.totalAmount }
    }

    private var totalHours: Double {
        filteredActivities.reduce(0) { $0 + $1.hours }
    }

    private var averagePerHour: Double {
        totalHours == 0 ? 0 : totalAmount / totalHours
    }

    // Summary by activity type
    private var breakdown: [(type: ActivityType, total: Double, count: Int)] {
        var dict: [ActivityType: (Double, Int)] = [:]
        for act in filteredActivities {
            let type = ActivityType(rawValue: act.activityType ?? "") ?? .others
            let existing = dict[type] ?? (0, 0)
            dict[type] = (existing.0 + act.totalAmount, existing.1 + 1)
        }
        return dict.map { (type: $0.key, total: $0.value.0, count: $0.value.1) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Period picker
                    Picker("Perioadă", selection: $selectedPeriod) {
                        ForEach(ReportPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Invoiced filter
                    Picker("Facturare", selection: $selectedInvoiceFilter) {
                        ForEach(InvoiceFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Custom date range
                    if selectedPeriod == .custom {
                        VStack(spacing: 0) {
                            DatePicker("De la", selection: $customStart, displayedComponents: .date)
                                .padding()
                            Divider().padding(.leading)
                            DatePicker("Până la", selection: $customEnd,
                                       in: customStart..., displayedComponents: .date)
                                .padding()
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Period label
                    let (start, end) = dateRange()
                    HStack {
                        Text(periodLabel(start: start, end: end))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Summary cards - 2 columns
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ReportCardView(
                            title: "Total încasat",
                            value: totalAmount.currencyString,
                            icon: "eurosign.circle.fill",
                            color: .green
                        )
                        ReportCardView(
                            title: "Sesiuni",
                            value: "\(filteredActivities.count)",
                            icon: "calendar.badge.clock",
                            color: .blue
                        )
                        ReportCardView(
                            title: "Total ore",
                            value: totalHours.hoursString,
                            icon: "clock.fill",
                            color: .orange
                        )
                        ReportCardView(
                            title: "Medie/oră",
                            value: averagePerHour.currencyString,
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Breakdown by type
                    if !breakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Defalcare pe tip")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(breakdown, id: \.type) { item in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(item.type.color.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: item.type.symbolName)
                                                .font(.system(size: 16))
                                                .foregroundStyle(item.type.color)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.type.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("\(item.count) sesiu\(item.count == 1 ? "ne" : "ni")")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(item.total.currencyString)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .padding()

                                    if item.type != breakdown.last?.type {
                                        Divider().padding(.leading, 60)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }

                    // Activity list for period
                    if !filteredActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Activități")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(filteredActivities) { activity in
                                    ActivityRowView(activity: activity)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    if activity != filteredActivities.last {
                                        Divider().padding(.leading, 68)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Nicio activitate în această perioadă")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rapoarte")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !filteredActivities.isEmpty {
                        let (start, end) = dateRange()
                        let label = periodLabel(start: start, end: end)
                        let pdfData = generatePDFData(label: label)
                        
                        if let data = pdfData {
                            ShareLink(
                                item: PDFExportDocument(data: data, label: label),
                                preview: SharePreview("Raport \(label)", image: Image(systemName: "doc.richtext.fill"))
                            ) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func dateRange() -> (Date, Date) {
        let now = Date()
        switch selectedPeriod {
        case .week:
            return (now.startOfWeek, now.endOfWeek)
        case .month:
            return (now.startOfMonth, now.endOfMonth)
        case .custom:
            return (customStart.startOfDay, customEnd.endOfDay)
        }
    }

    private func periodLabel(start: Date, end: Date) -> String {
        switch selectedPeriod {
        case .week:
            return "Săptămâna \(start.shortFormatted) – \(end.shortFormatted)"
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: Date()).capitalized
        case .custom:
            return "\(start.shortFormatted) – \(end.shortFormatted)"
        }
    }
    
    @MainActor
    private func generatePDFData(label: String) -> Data? {
        let pdfView = PDFReportView(
            periodLabel: label,
            activities: Array(filteredActivities),
            totalAmount: totalAmount,
            totalHours: totalHours
        )
        
        let renderer = ImageRenderer(content: pdfView)
        renderer.scale = 3.0
        
        // Generate a temporary file URL
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
        
        // Cleanup
        try? FileManager.default.removeItem(at: url)
        
        return generatedData
    }
}

#Preview {
    ReportsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
