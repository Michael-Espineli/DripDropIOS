//
//  GenerateJobFromLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/25.
//

import SwiftUI

struct GenerateJobFromLaborContract: View {
    //Init
    init(
        dataService:any ProductionDataServiceProtocol,
        laborContract:LaborContract,
        isPresented:Binding<Bool>,
        isFullScreenCover:Bool
    ){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
        self._isPresented = isPresented
        _isFullScreenCover = State(wrappedValue: isFullScreenCover)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractViewModel
    
    //Formatting
    @Binding var isPresented:Bool
    @State var isFullScreenCover:Bool
    
    //Form
    @State var laborContract:LaborContract
    @State var isLoading:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                Text("Admin Picker")
                
                Picker("Admin", selection: $VM.selectedAdmin) {
                    Text("Select Admin").tag(CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor))
                    ForEach(VM.companyUsers){ user in
                        Text(user.userName).tag(user)
                    }
                }
                Button(action: {
                    Task{
                        do {
                            try await VM.generateJobFromLaborContract(laborContract: laborContract)
                            isPresented.toggle()
                        } catch {
                            print(error)
                        }
                    }
                }, label: {
                    HStack{
                        Spacer()
                        Text("Create Job")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                })
            }
            .padding(8)
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadGenerateJobFromLaborContract(companyId: currentCompany.id, laborContractId: laborContract.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    GenerateJobFromLaborContract()
//}
