//
//  EarningsChartView.swift
//  Financial Growth
//
//  Created by Antigravity on 04.03.2026.
//

import SwiftUI
import Charts

// MARK: - Data model for a single chart bar
struct EarningsDataPoint: Identifiable {
    let id = UUID()
    let label: String       // Display label on X axis
    let date: Date          // Used for sorting and tooltip
    let amount: Double
}

// MARK: - Chart View
struct EarningsChartView: View {

    let dataPoints: [EarningsDataPoint]
    let period: ReportPeriod   // .week or .month

    // Currently highlighted bar (for tap interaction)
    @State private var selectedDataPoint: EarningsDataPoint? = nil

    private var maxAmount: Double {
        dataPoints.map(\.amount).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(period == .week ? "Evoluție încasări săptămânale" : "Evoluție încasări lunare")
                    .font(.headline)
                Spacer()
                if let sel = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(sel.amount.currencyString)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .transition(.opacity)
                }
            }

            if dataPoints.isEmpty || dataPoints.allSatisfy({ $0.amount == 0 }) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Nu există date pentru perioadele anterioare")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            } else {
                Chart {
                    ForEach(dataPoints) { dp in
                        BarMark(
                            x: .value("Perioadă", dp.label),
                            y: .value("Încasat", dp.amount)
                        )
                        .foregroundStyle(
                            dp.id == selectedDataPoint?.id
                                ? Color.blue.gradient
                                : Color.blue.opacity(0.5).gradient
                        )
                        .cornerRadius(6)
                        .annotation(position: .top, alignment: .center) {
                            if dp.id == selectedDataPoint?.id && dp.amount > 0 {
                                Text(dp.amount.currencyString)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .fixedSize()
                            }
                        }
                    }

                    // Reference line at average
                    if maxAmount > 0 {
                        let avg = dataPoints.map(\.amount).reduce(0, +) / Double(max(dataPoints.count, 1))
                        RuleMark(y: .value("Medie", avg))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(Color.purple.opacity(0.7))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("med.")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.purple)
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(.systemGray5))
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text(compactCurrency(d))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                                        if let label: String = proxy.value(atX: x) {
                                            selectedDataPoint = dataPoints.first { $0.label == label }
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            selectedDataPoint = nil
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 180)
                .animation(.easeInOut(duration: 0.3), value: dataPoints.map(\.amount))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // Compact currency: "1.250 €" → "1,2K €"
    private func compactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fK €", value / 1000)
        }
        return String(format: "%.0f €", value)
    }
}
