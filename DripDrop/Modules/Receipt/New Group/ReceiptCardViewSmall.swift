//
//  ReceiptCardViewSmall.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct ReceiptCardViewSmall: View {
    var receipt: Receipt

    var body: some View {
        mobileReceiptCard
    }

    private var mobileReceiptCard: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(statusColor)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(storeName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(invoiceLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(receipt.costAfterTax, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(shortDate(date: receipt.date ?? Date()))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 7) {
                    receiptPill(
                        "\(receipt.numberOfItems) item\(receipt.numberOfItems == 1 ? "" : "s")",
                        systemImage: "shippingbox"
                    )

                    if !techName.isEmpty {
                        receiptPill(techName, systemImage: "person")
                    }

                    if let fileCount = receipt.pdfUrlList?.count, fileCount > 0 {
                        receiptPill(
                            "\(fileCount) file\(fileCount == 1 ? "" : "s")",
                            systemImage: "paperclip"
                        )
                    }
                }

                if receipt.cost > 0, receipt.cost != receipt.costAfterTax {
                    Text("Before tax \(receipt.cost, format: .currency(code: "USD"))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var statusColor: Color {
        if receipt.costAfterTax > 0 {
            return .poolGreen
        }

        return .orange
    }

    private var storeName: String {
        let name = receipt.storeName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Receipt" : name
    }

    private var techName: String {
        receipt.tech?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var invoiceLabel: String {
        let invoice = receipt.invoiceNum?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return invoice.isEmpty ? "No invoice number" : "Invoice \(invoice)"
    }

    private func receiptPill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
    }
}

struct ReceiptCardViewSmall_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptCardViewSmall(
            receipt: Receipt(
                id: "id",
                invoiceNum: "69420",
                date: Date(),
                storeId: "334613456978234",
                storeName: "Alpha",
                tech: "Michael Espineli",
                techId: "",
                purchasedItemIds: [],
                numberOfItems: 7,
                cost: 530.68,
                costAfterTax: 630.49
            )
        )
    }
}
