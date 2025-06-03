//
//  ContractCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct ContractCardView: View {
    let contract:RecurringContract
    var body: some View {
        VStack{
            HStack{
                Text("\(contract.internalCustomerName)")
                Spacer()
            }
            HStack{
                switch contract.status {
                    case .pending:
                        Pending
                    case .accepted:
                        Accepted
                    case .past:
                        Past
                    case .rejected:
                        Rejected
                    case .draft:
                        Draft
                }
           
                Text("Rate: ")
                    .font(.footnote)
                Text("\(Double(contract.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    .font(.footnote)
            }
        }
        .modifier(ListButtonModifier())
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
                .foregroundColor(Color.black)
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
                .foregroundColor(Color.black)
                .font(.footnote)
            
        }
    }
    var Past: some View {
        HStack{
            Text("Past")
                .padding(5)
                .background(Color.red)
                .cornerRadius(5)
                .foregroundColor(Color.black)
                .font(.footnote)
        }
    }
    var Rejected: some View {
        HStack{
            Text("Rejected")
                .padding(5)
                .background(Color.red)
                .cornerRadius(5)
                .foregroundColor(Color.black)
                .font(.footnote)
        }
    }
    var Draft: some View {
        HStack{
            Text("Draft")
                .padding(5)
                .background(Color.red)
                .cornerRadius(5)
                .foregroundColor(Color.black)
                .font(.footnote)
        }
    }
}
