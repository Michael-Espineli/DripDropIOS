//
//  MoveServiceStopsConfirmation.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 2/1/24.
//

import SwiftUI
enum MoveServiceStopType:String {
    case permanant = "Permanant"
    case oneTime = "One Time"
}
struct MoveServiceStopsConfirmation: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var companyUserVM = CompanyUserViewModel()
    @State var selectedServiceStopList: [ServiceStop]
    init(dataService:any ProductionDataServiceProtocol,selectedServiceStopList:[ServiceStop]){
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _selectedServiceStopList = State(wrappedValue: selectedServiceStopList)
    }
    @State var tech:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor)
    @State var date:Date = Date()
    @State var moveType: MoveServiceStopType = .oneTime
    var body: some View {
       info
            .task{
                if let company = masterDataManager.currentCompany {
                    do {
                        try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                        
                    } catch {
                        print("Error Getting Users By status")
                    }
                }
            }
    }
}

extension MoveServiceStopsConfirmation {
    var info: some View {
        VStack{
            HStack{
                Button(action: {
                    moveType = .oneTime
                }, label: {
                    Text(MoveServiceStopType.oneTime.rawValue)
                        .padding(8)
                        .background(moveType == .oneTime ? Color.poolBlue : Color.darkGray)
                        .foregroundColor(Color.poolWhite)
                        .cornerRadius(8)
                })
                Spacer()
                Button(action: {
                    moveType = .permanant
                }, label: {
                    Text(MoveServiceStopType.permanant.rawValue)
                        .padding(8)
                        .background(moveType == .permanant ? Color.poolBlue : Color.darkGray)
                        .foregroundColor(Color.poolWhite)
                        .cornerRadius(8)
                })
            }
            .padding(.horizontal,16)
            Picker("", selection: $tech) {
                Text("Pick tech").tag("Tech")
                ForEach(companyUserVM.companyUsers) { user in
                    Text(user.userName).tag(user)
                }
            }
            DatePicker(selection: $date, displayedComponents: .date) {
            }
            button
        }
    }
    var button: some View {
        Button(action: {
            Task{
                if let company  = masterDataManager.currentCompany {
                    do {
                        try await serviceStopVM.updateServiceStopListServiceDate(companyId: company.id, serviceStopList: selectedServiceStopList, date: date,companyUser:tech)
                        dismiss()
                    } catch {
                        print("failed to Update")
                    }
                }
            }
            
        }, label: {
            Text("Submit")
                .modifier(SubmitButtonModifier())

        })
        .background(Color.white // any non-transparent background
            .cornerRadius(5)
          .shadow(color: Color.black, radius: 5, x: 5, y: 5)
        )
    }
}
