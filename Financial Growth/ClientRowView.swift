//
//  ClientRowView.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import SwiftUI

struct ClientRowView: View {

    let client: Client

    var body: some View {
        HStack(spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(client.name ?? "Fără nume")
                    .font(.headline)

                if let email = client.email, !email.isEmpty {
                    Label(email, systemImage: "envelope")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let phone = client.phone, !phone.isEmpty {
                    Label(phone, systemImage: "phone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Activity count badge
            let count = client.activities?.count ?? 0
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        let parts = (client.name ?? "?").split(separator: " ")
        let letters = parts.compactMap { $0.first }.prefix(2)
        return String(letters).uppercased()
    }
}
