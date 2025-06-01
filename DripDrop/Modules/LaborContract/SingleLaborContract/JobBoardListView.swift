//
//  JobBoardListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class JobBoardListViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    func onLoad(companyId:String,userId:String) async throws {
        
    }
}

struct JobBoardListView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: JobBoardListViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : JobBoardListViewModel
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    Text("Job Board List")
                }
            }
        }
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
//    JobBoardListView()
//}
