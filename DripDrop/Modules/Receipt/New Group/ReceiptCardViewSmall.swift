//
//  ReceiptCardViewSmall.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct ReceiptCardViewSmall: View {
    var receipt:Receipt
    var body: some View {
        ZStack{
            HStack{
                VStack{
                        Text("Invoice:\(receipt.invoiceNum ?? "invoice")")
                    Text("\(receipt.storeName ?? "storeName")")
                    Text("\(shortDate(date:receipt.date ?? Date()))")
                }
                Spacer()
                VStack{
                    Text("\(receipt.tech ?? "")")
                    Text("CItems $\(String(format:"%2.f",receipt.numberOfItems))")
                        .font(.footnote)
                    Text("Cost After Tax: $\(String(format:"%2.f",receipt.costAfterTax))")
                        .font(.footnote)
                }
                Image(systemName: "chevron.compact.right")
            }
            .modifier(ListButtonModifier())
        }
    }
}

struct ReceiptCardViewSmall_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptCardViewSmall(receipt: Receipt(id: "id",
                                              invoiceNum: "69420",
                                              date: Date(),
                                              storeId: "334613456978234",
                                              storeName: "Alpha",
                                              tech: "Michael Espineli",
                                              techId: "",
                                              purchasedItemIds: [],
                                              numberOfItems: 7,
                                              cost: 530.68,
                                              costAfterTax: 630.49))
    }
}
