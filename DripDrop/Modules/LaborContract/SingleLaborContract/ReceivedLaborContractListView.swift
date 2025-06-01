//
//  ReceivedLaborContractListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//


import SwiftUI

@MainActor
final class ReceivedLaborContractListViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var laborContracts : [LaborContract] = []
    @Published var showNewSheet : Bool = false

    func onLoad(companyId:String,userId:String) async throws {
        print("On Load Single Labor Contract List View - [SingleLaborContractListViewModel]")
        let sentContracts = try await dataService.getLaborContractsBySenderId(senderId: companyId)
        let receivedContracts = try await dataService.getLaborContractsByReceiverId(receiverId: companyId)
        self.laborContracts = sentContracts + receivedContracts
        print("Finished")
    }
}

struct ReceivedLaborContractListView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: ReceivedLaborContractListViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : ReceivedLaborContractListViewModel
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    ForEach(VM.laborContracts) { contract in
                        NavigationLink(value: Route.laborContractDetailView(dataService: dataService, contract: contract), label: {
                            LaborContractCardView(laborContract: contract)
                        })
                    }
                }
            }
            .padding(8)
            icons
        }
        .navigationTitle("Labor Contracts")
        .task{
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, userId: user.id)
                } catch {
                    print("Error - [LaborContractListView]")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    LaborContractListView()
//}
extension ReceivedLaborContractListView {
    var icons : some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        VM.showNewSheet.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                    })
                }
                .padding()
            }
        }
    }
}
