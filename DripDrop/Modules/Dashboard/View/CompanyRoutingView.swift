//
//  CompanyRoutingView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/12/24.
//

import SwiftUI
@MainActor
final class CompanyRoutingViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    func onLoad(companyId:String,companies:[Company]){
        Task{
            do {
                
            } catch {
                print(error)
            }
        }
    }
}
struct CompanyRoutingView: View {
    
    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: CompanyRoutingViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var VM : CompanyRoutingViewModel
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView{
                    info
                }


            }
            .padding(8)
        }
    }
}

//#Preview {
//    CompanyRoutingView()
//}
extension CompanyRoutingView {
    var info: some View {
        VStack{
            if let currentCompany = masterDataManager.currentCompany {
                WorkPreviewBasedOnCompany(dataService: dataService, company: currentCompany)
            } else {
                Text("No Company Selected")
                    .modifier(MockButtonModifier())
            }
        }
    }
}

