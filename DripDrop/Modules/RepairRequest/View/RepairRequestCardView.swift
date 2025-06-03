//
//  RepairRequestCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/13/24.
//

import SwiftUI

struct RepairRequestCardView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    let repairRequest:RepairRequest
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                switch masterDataManager.mainScreenDisplayType {
                case .compactList:
                    compact
                case .preview:
                    info
                case .fullPreview:
                    status
                    info
                }
             
            }
            .frame(maxWidth: .infinity)
        }
        .modifier(ListButtonModifier())
        .fontDesign(.monospaced)
    }
}
extension RepairRequestCardView {
    var compact: some View {
        HStack{
            Text("\(repairRequest.id)")
            Text("\(repairRequest.customerName)")
                .lineLimit(2, reservesSpace: true)
            Text("\(repairRequest.status.rawValue)")
                .padding(5)
                .background(getColor(status:repairRequest.status))
                .foregroundColor(getForgroundColor(status: repairRequest.status))
                .cornerRadius(5)
                .lineLimit(2, reservesSpace: true)
            Spacer()
        }
    }
    var status: some View {
        HStack{
            Text("\(repairRequest.id)")
            Spacer()
            Text("\(repairRequest.status.rawValue)")
                .lineLimit(2, reservesSpace: true)
                .padding(5)
                .background(getColor(status:repairRequest.status))
                .foregroundColor(getForgroundColor(status: repairRequest.status))
                .cornerRadius(5)
        }
    }
    var info: some View {
        VStack{
            Text("\(repairRequest.customerName)")
                .lineLimit(2, reservesSpace: true)

            HStack{
                Text("Tech: \(repairRequest.requesterName)")
                Text("Date: \(fullDate(date:repairRequest.date))")
            }
        }
    }
    func getColor(status:RepairRequestStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .resolved:
            color = Color.poolGreen
        case .unresolved:
            color = Color.poolRed
        case .inprogress:
            color = Color.yellow
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
        }
        return color
    }
}
