//
//  ContractCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct ContractCardView: View {
    let contract:Contract
    var body: some View {
        VStack{
            HStack{
                Text("\(contract.customerName)")
                Spacer()
                switch contract.status {
                case "Pending":
                    Pending
                case "Accepted":
                    Accepted
                case "Past":
                    Past
                default:
                    Pending
                }
            }
            HStack{
                Text("Start Date: ")
                    .font(.footnote)
                if let date = contract.startDate {
                    Text("\(fullDate(date: date))")
                        .font(.footnote)
                }
                Text("Rate: ")
                    .font(.footnote)
                Text("\(contract.rate, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    .font(.footnote)
            }
        }
    }
}
extension ContractCardView {
    var Accepted: some View {
        HStack{
            Text("Status: ")
                .font(.footnote)
            Text("Accepted")
                .padding(5)
                .background(Color.green)
                .cornerRadius(5)
                .foregroundColor(Color.basicFontText)
                .font(.footnote)
            
        }
        
    }
    var Pending: some View {
        HStack{
            Text("Status: ")
                .font(.footnote)
            Text("Pending")
                .padding(5)
                .background(Color.yellow)
                .cornerRadius(5)
                .foregroundColor(Color.basicFontText )
                .font(.footnote)
            
        }
    }
    var Past: some View {
        HStack{
            Text("Past")
                .padding(5)
                .background(Color.red)
                .cornerRadius(5)
                .foregroundColor(Color.basicFontText)
                .font(.footnote)
        }
    }
}
