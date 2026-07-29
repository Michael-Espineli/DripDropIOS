//
//  DataBaseItemCardView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/8/23.
//

import SwiftUI

enum DataBaseItemMoneyFormatter {
    static func moneyFromCents(_ cents: Double) -> String {
        moneyFromCents(Int(cents.rounded()))
    }

    static func moneyFromCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }

    static func customerPriceText(for item: DataBaseItem) -> String {
        guard item.billable else {
            return "Not billable"
        }

        guard let sellPrice = item.sellPrice,
              sellPrice > 0 else {
            return "No price"
        }

        return moneyFromCents(sellPrice)
    }

    static func costText(for item: DataBaseItem) -> String {
        moneyFromCents(item.rate)
    }

    static func dollarInputText(fromCents cents: Double?) -> String {
        guard let cents else { return "" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0

        return formatter.string(from: NSNumber(value: cents / 100.0)) ?? ""
    }

    static func centsFromDollarInput(_ text: String) -> Double {
        let filtered = text.filter { ".0123456789".contains($0) }
        let dollars = Double(filtered) ?? 0

        return (dollars * 100.0).rounded()
    }

    static func hasCustomerPrice(_ item: DataBaseItem) -> Bool {
        guard item.billable else { return false }
        guard let sellPrice = item.sellPrice else { return false }

        return sellPrice > 0
    }
}

struct DataBaseItemCardView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    
    //Variables Received
    @State var dataBaseItem:DataBaseItem
    //View Models Declared
    
    //Variables Declared For Use

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(priceTint)
                    .frame(width: 38, height: 38)
                    .background(priceTint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(dataBaseItem.name.isEmpty ? "Unnamed Item" : dataBaseItem.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(dataBaseItem.category.rawValue) • \(dataBaseItem.subCategory.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    billablePill

                    if dataBaseItem.billable {
                        pricePill
                    }
                }
            }

            if !dataBaseItem.description.isEmpty {
                Text(dataBaseItem.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                detailChip(title: "Cost", value: DataBaseItemMoneyFormatter.costText(for: dataBaseItem))
                detailChip(title: "UOM", value: dataBaseItem.UOM.rawValue)
            }

            HStack(spacing: 8) {
                if !dataBaseItem.storeName.isEmpty {
                    Label(dataBaseItem.storeName, systemImage: "storefront")
                }

                Spacer()

                Text(shortDate(date: dataBaseItem.dateUpdated))
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var pricePill: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Price")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(DataBaseItemMoneyFormatter.customerPriceText(for: dataBaseItem))
                .font(.caption.weight(.bold))
                .foregroundStyle(priceTint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(priceTint.opacity(0.12), in: Capsule())
    }

    private var billablePill: some View {
        Label(dataBaseItem.billable ? "Billable" : "Not billable",
              systemImage: dataBaseItem.billable ? "checkmark.seal.fill" : "nosign")
            .font(.caption2.weight(.bold))
            .foregroundStyle(dataBaseItem.billable ? .green : .secondary)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background((dataBaseItem.billable ? Color.green : Color.secondary).opacity(0.12), in: Capsule())
    }

    private func detailChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var priceTint: Color {
        guard dataBaseItem.billable else { return .secondary }

        return DataBaseItemMoneyFormatter.hasCustomerPrice(dataBaseItem) ? .green : .orange
    }

    private var iconName: String {
        switch dataBaseItem.category {
        case .chems:
            return "drop"
        case .equipment:
            return "wrench.and.screwdriver"
        case .tools:
            return "hammer"
        default:
            return "shippingbox"
        }
    }
}
