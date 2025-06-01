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
                .fullScreenCover(isPresented: $showSheet, content: {
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                showSheet.toggle()
                            }, label: {
                                Text("Dismiss")
                                    .modifier(DismissButtonModifier())
                            })
                        }
                        LaborContractDetailView(dataService: dataService, laborContract: laborContract)
                        Spacer()
                    }
                })
            }
        }
    }
}


