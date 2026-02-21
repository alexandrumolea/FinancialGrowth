//
//  ReportExportHelper.swift
//  Financial Growth
//
//  Created by Antigravity on 19.02.2026.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - PDF Export Helper
struct PDFExportDocument: Transferable {
    let data: Data
    let label: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { document in
            document.data
        }
        .suggestedFileName { document in
            "Raport_\(document.label.replacingOccurrences(of: " ", with: "_")).pdf"
        }
    }
}
