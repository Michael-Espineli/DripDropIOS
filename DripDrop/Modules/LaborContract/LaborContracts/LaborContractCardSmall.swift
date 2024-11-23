//
//  LaborContractCardSmall.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import SwiftUI

struct LaborContractCardSmall: View {
    @EnvironmentObject var dataService : ProductionDataService
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:RepeatingLaborContract){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : LaborContractViewModel
    
    //Form
    @State var laborContract:RepeatingLaborContract
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
            HStack{
                    Text("Date Sent:")
                        .fontWeight(.bold)
                Text("DateSent \(fullDate(date:laborContract.dateSent))")
                
                Spacer()
 
            }
            HStack{
                Text("Status:")
                    .fontWeight(.bold)
            Text("\(laborContract.status.rawValue)")
                    .padding(8)
                    .background(VM.getBackGroundColor(status: laborContract.status))
                    .cornerRadius(8)
                    .foregroundColor(VM.getForeGroundColor(status: laborContract.status))
                Spacer()
            }
        }
        .modifier(ListButtonModifier())
        .padding(.horizontal,8)
    }
}

