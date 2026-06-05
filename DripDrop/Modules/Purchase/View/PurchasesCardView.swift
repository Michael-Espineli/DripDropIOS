//
//  PurchasesCardView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/15/23.
//

import SwiftUI
struct PurchasesCardView: View{
    var item: PurchasedItem
    
    var body: some View{
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(statusColor)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name.isEmpty ? "Purchased Item" : item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(item.venderName.isEmpty ? "No vendor" : item.venderName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(item.totalAfterTax, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text(shortDate(date: item.date))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 7) {
                    purchasePill(item.billable ? (item.invoiced ? "Invoiced" : "Billable") : "Non-billable", systemImage: item.billable ? "doc.text" : "nosign")
                    purchasePill("Qty \(item.quantityString)", systemImage: "number")
                    if !item.techName.isEmpty {
                        purchasePill(item.techName, systemImage: "person")
                    }
                }

                if !item.customerName.isEmpty || !item.jobId.isEmpty || !item.invoiceNum.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        if !item.invoiceNum.isEmpty {
                            Text("Invoice \(item.invoiceNum)")
                        }
                        if !item.customerName.isEmpty {
                            Text(item.customerName)
                        }
                        if !item.jobId.isEmpty {
                            Text("Job \(item.jobId)")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var statusColor: Color {
        if item.billable {
            return item.invoiced ? .green : .red
        }
        return .yellow
    }

    private func purchasePill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
    }
}
