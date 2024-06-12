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
        ZStack{
            HStack{
                if item.billable {
                    Rectangle()
                        .fill(item.invoiced ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
                        .frame(width: 5)
                } else {
                    Rectangle()
                    .fill(Color.yellow.opacity(0.5))
                    .frame(width: 5)
                }
                VStack{
                    HStack{
                        Text(item.name)
                        Spacer()
                    }
                    HStack{
                        VStack{
                            Text(item.invoiceNum)
                            Text(shortDate(date: item.date))
                                .font(.footnote)
                        }
                        Spacer()
                        VStack{
                            Text("Total: \(item.totalAfterTax, format: .currency(code: "USD"))")
                            HStack{
                                Text("\(item.quantityString) X" )
                                    .font(.footnote)
                                Text("\(item.price, format: .currency(code: "USD"))")
                                    .font(.footnote)
                            }
                        }
                    }
                    HStack{
                        Text("Tech : ")
                            .lineLimit(1)
                            .font(.footnote)
                        Text(item.techName )
                            .lineLimit(1)
                            .font(.footnote)
                        VStack{
                            if item.customerName != "" {
                                    Text("Customer : \(item.customerName )")
                                        .lineLimit(1)
                                        .font(.footnote)
                            }
                            if item.jobId != "" {
                                Text("Job : \(item.jobId)")
                                    .lineLimit(1)
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                
                    }
                }
            }
//            .background(item.invoiced ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
        }
    }
}
