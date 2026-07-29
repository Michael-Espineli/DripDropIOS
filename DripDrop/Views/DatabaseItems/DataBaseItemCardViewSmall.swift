//
//  DataBaseItemCardViewSmall.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/2/24.
//


import SwiftUI

struct DataBaseItemCardViewSmall: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    
    //Variables Received
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var dataBaseItem:DataBaseItem
    //View Models Declared
    
    //Variables Declared For Use

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shippingbox")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(priceTint)
                    .frame(width: 32, height: 32)
                    .background(priceTint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(dataBaseItem.name.isEmpty ? "Unnamed Item" : dataBaseItem.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(dataBaseItem.size) \(dataBaseItem.UOM.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label(dataBaseItem.billable ? "Billable" : "Not billable",
                          systemImage: dataBaseItem.billable ? "checkmark.seal.fill" : "nosign")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(dataBaseItem.billable ? .green : .secondary)

                    if dataBaseItem.billable {
                        Text(DataBaseItemMoneyFormatter.customerPriceText(for: dataBaseItem))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(priceTint)
                            .lineLimit(1)
                    }
                }
            }

            HStack {
                Text("Cost \(DataBaseItemMoneyFormatter.costText(for: dataBaseItem))")
                Spacer()
                Text(shortDate(date: dataBaseItem.dateUpdated))
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var priceTint: Color {
        guard dataBaseItem.billable else { return .secondary }

        return DataBaseItemMoneyFormatter.hasCustomerPrice(dataBaseItem) ? .green : .orange
    }
}
