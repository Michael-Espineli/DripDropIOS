//
//  LaborContractMediumCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI

struct LaborContractMediumCardView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    let laborContract:RepeatingLaborContract
    var body: some View {
        VStack(alignment:.leading){
            if let company = masterDataManager.currentCompany {
                if company.id != laborContract.senderId {
                    HStack{
                        Text("Sender Name:")
                            .fontWeight(.bold)
                        Text("\(laborContract.senderName)")
                        Spacer()
                    }
                }
                if company.id != laborContract.receiverId {
                    HStack{
                        Text("Receiver Name:")
                            .fontWeight(.bold)
                        Text("\(laborContract.receiverName)")
                        Spacer()
                    }
                }
            }
            HStack{
                Text("Status:")
                    .fontWeight(.bold)
            Text("\(laborContract.status.rawValue)")
                    .padding(8)
                    .background(getBackGroundColor(status: laborContract.status))
                    .cornerRadius(8)
                    .foregroundColor(getForeGroundColor(status: laborContract.status))
                Spacer()
            }
            HStack{
                Text("Notes:")
                    .fontWeight(.bold)
            Text("\(laborContract.notes)")
                    .modifier(TextFieldModifier())
                Spacer()
            }
            HStack{
                Text("Date Sent:")
                    .fontWeight(.bold)
            Text("\(fullDate(date:laborContract.dateSent))")
                Spacer()
            }

            HStack{
                    Text("Start Date: \(fullDate(date: Date()))")
                    Spacer()
         
                    let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
                    Text("Valid Until : \(fullDate(date: endDate))")
                
            }
            Divider()
                HStack{
                    Text("Accounts")
                    Spacer()
                }
        }
        .frame(maxWidth: .infinity)
        .fontDesign(.monospaced)
    }
}

#Preview {
    LaborContractMediumCardView(laborContract: MockDataService.mockLaborContracts.first!)
}
extension LaborContractMediumCardView {
    func getBackGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolGreen
        case .past:
            return Color.poolRed
        case .pending:
            return Color.poolYellow
   
        }
    }
    func getForeGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolWhite
        case .past:
            return Color.poolWhite
        case .pending:
            return Color.poolBlack
        }
    }
}
