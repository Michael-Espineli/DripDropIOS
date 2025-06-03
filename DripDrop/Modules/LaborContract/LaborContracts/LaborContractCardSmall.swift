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
    init(dataService:any ProductionDataServiceProtocol,laborContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : RecurringLaborContractViewModel
    
    //Form
    @State var laborContract:ReccuringLaborContract
    var body: some View {
        VStack{
            if let company = masterDataManager.currentCompany {
                if company.id != laborContract.senderId {
                    HStack{
                        Text("From:")
                            .fontWeight(.bold)
                            .padding(3)
                            .background(Color.poolYellow.opacity(0.5))
                            .cornerRadius(8)
                        Text("\(laborContract.senderName)")
                        Spacer()
                    }
                }
                if company.id != laborContract.receiverId {
                    HStack{
                        Text("To:")
                            .fontWeight(.bold)
                            .padding(3)
                            .background(Color.poolBlue.opacity(0.5))
                            .cornerRadius(8)
                        Text("\(laborContract.receiverName)")
                        Spacer()
                    }
                }
            }
            HStack{
                    Text("Date Sent:")
                        .fontWeight(.bold)
                Text("\(shortDate(date:laborContract.dateSent))")
                
                Spacer()
 
            }
            HStack{

                Text("\(laborContract.status.rawValue)")
                    .padding(.horizontal,6)
                    .padding(.vertical,4)
                    .background(VM.getBackGroundColor(status: laborContract.status))
                    .cornerRadius(4)
                    .foregroundColor(VM.getForeGroundColor(status: laborContract.status))
                Spacer()
                if laborContract.isActive {
                    Text("Active")
                            .padding(.horizontal,6)
                            .padding(.vertical,4)
                            .background(Color.poolGreen)
                            .cornerRadius(4)
                            .foregroundColor(Color.poolWhite)
                } else {
                    Text("In Active")
                            .padding(.horizontal,6)
                            .padding(.vertical,4)
                            .background(Color.poolRed)
                            .cornerRadius(4)
                            .foregroundColor(Color.poolWhite)
                }
            }
            .font(.footnote)
        }
        .modifier(ListButtonModifier())
        .padding(.horizontal,8)
    }
}

