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
                    Text("Items: \(String(receipt.numberOfItems))")
                        .font(.footnote)
                    Text("Cost After Tax: \(String(receipt.costAfterTax))")
                        .font(.footnote)
                }
                Image(systemName: "chevron.compact.right")
            }
             .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
            .background(Color.gray.opacity(0.5))
            .cornerRadius(10)
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
