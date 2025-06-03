//
//  LaborContractCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/25.
//

import SwiftUI

struct LaborContractCardView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager

    @State var laborContract:LaborContract
    @State var showSheet:Bool = false
    func getBackGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolYellow
        case .finished:
            return Color.poolGreen
        case .rejected:
            return Color.poolRed
        case .pending:
            return Color.orange
        }
    }
    func getForeGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolBlack
        case .finished:
            return Color.poolWhite
        case .rejected:
            return Color.poolWhite
        case .pending:
            return Color.poolBlack
        }
    }
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    if let company = masterDataManager.currentCompany {
                        
                        if company.id != laborContract.senderId {
                            HStack{
                                Text("From:")
                                    .fontWeight(.bold)
                                Text("\(laborContract.senderName)")
                                Spacer()
                            }
                        }
                        if company.id != laborContract.receiverId {
                            HStack{
                                Text("To:")
                                    .fontWeight(.bold)
                                Text("\(laborContract.receiverName)")
                                Spacer()
                            }
                        }
                    }
                }
                HStack{
                    Text(laborContract.customerName)
                    Spacer()
                }
                if laborContract.status == .pending {
                    //Maybe show this all the time
                    HStack{
                        Text("Sent:")
                            .fontWeight(.bold)
                        Text("\(shortDate(date: laborContract.dateSent))")
                        Spacer()
                    }
                    HStack{
                        Text("Last Day to Accept: ")
                            .fontWeight(.bold)
                        Text("\(shortDate(date: laborContract.lastDateToAccept))")
                        Spacer()
                    }
                }
                HStack{
                    Text("\(laborContract.status.rawValue)")
                        .padding(.horizontal,6)
                        .padding(.vertical,4)
                        .background(getBackGroundColor(status: laborContract.status))
                        .cornerRadius(4)
                        .foregroundColor(getForeGroundColor(status: laborContract.status))
                    Spacer()
                    Text(laborContract.isInvoiced ? "Invoiced": "Not Invoiced")
                        .padding(.horizontal,6)
                        .padding(.vertical,4)
                        .background(laborContract.isInvoiced ? Color.poolGreen : Color.poolRed)
                        .cornerRadius(4)
                        .foregroundColor(Color.poolWhite)

                }
                .font(.footnote)
            }
        }
        .modifier(ListButtonModifier())
    }
}


