//
//  RecurringLaborContractCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/16/24.
//

import SwiftUI

struct RecurringLaborContractCardView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager

    @State var laborContract:ReccuringLaborContract
    @State var showSheet:Bool = false
    var body: some View {
        VStack{
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
//            Text("Recurring Work - \(laborContract.recurringWork.count)")
            HStack{
                Spacer()
                Button(action: {
                    showSheet.toggle()
                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(Color.red)
                    .padding(3)
                })
                .sheet(isPresented: $showSheet, content: {
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                showSheet.toggle()
                            }, label: {
                                Image(systemName: "xmark")
                                    .modifier(DismissButtonModifier())
                            })
                        }
                        RecurringLaborContractDetailView(dataService: dataService, laborContract: laborContract)
                        Spacer()
                    }
                })
            }
        }
    }
}

