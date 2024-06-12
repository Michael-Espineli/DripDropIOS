//
//  RepairRequestCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/13/24.
//

import SwiftUI

struct RepairRequestCardView: View {
    let repairRequest:RepairRequest
    var body: some View {
        info
    }
}
extension RepairRequestCardView {
    var info: some View {
        HStack{
            VStack{
                    Text("Customer : \(repairRequest.customerName)")
                HStack{
                    Text("Tech: \(repairRequest.requesterName)")
                        .font(.footnote)
                    Text("Date: \(fullDate(date:repairRequest.date))")
                        .font(.footnote)
                    
                }
                HStack{
                    Text("\(repairRequest.id)")
Spacer()
                    Text("\(repairRequest.status.rawValue)")
                        .padding(5)
                        .background(getColor(status:repairRequest.status))
                        .foregroundColor(getForgroundColor(status: repairRequest.status))
                        .cornerRadius(5)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    func getColor(status:RepairRequestStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .resolved:
            color = Color.poolGreen
        case .unresolved:
            color = Color.red
        case .inprogress:
            color = Color.yellow
        default:
            color = Color.gray
        }
        return color
    }
    func getForgroundColor(status:RepairRequestStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .resolved:
            color = Color.white
        case .unresolved:
            color = Color.white
        case .inprogress:
            color = Color.black
        default:
            color = Color.black
        }
        return color
    }
}
