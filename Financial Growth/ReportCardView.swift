//
//  ReportCardView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI

struct ReportCardView: View {

    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ReportCardView(title: "Total", value: "3.500 €", icon: "eurosign.circle.fill", color: .green)
        .padding()
}
