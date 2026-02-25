//
//  ActivityRowView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI

struct ActivityRowView: View {

    @ObservedObject var activity: Activity

    private var activityType: ActivityType {
        ActivityType(rawValue: activity.activityType ?? "") ?? .others
    }

    private var dateRangeText: String {
        guard let start = activity.startDate, let end = activity.endDate else { return "" }
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return start.mediumFormatted
        }
        return "\(start.shortFormatted) – \(end.shortFormatted)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(activityType.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: activityType.symbolName)
                    .font(.system(size: 20))
                    .foregroundStyle(activityType.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(activityType.displayName)
                        .font(.headline)
                    if activity.isInvoiced != 0 {
                        Text("FACTURAT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Spacer()
                    Text(activity.totalAmount.currencyString)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                HStack {
                    Text(activity.client?.name ?? "Fără client")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(dateRangeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(activity.hours.hoursString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(activity.costPerHour.currencyString)/oră")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
