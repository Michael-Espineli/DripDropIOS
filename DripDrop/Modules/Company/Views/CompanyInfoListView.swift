//
//  CompanyInfoListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/15/25.
//

import SwiftUI
import PhotosUI
@MainActor
final class CompanyInfoListViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    @Published private(set) var postedCompany : Company? = nil

    func onLoad(companyId:String,jobPost:JobPost) async throws {
        self.postedCompany = try await dataService.getCompany(companyId: jobPost.companyId)
    }
}
struct CompanyInfoListView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: CompanyInfoListViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : CompanyInfoListViewModel
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                list
            }
        }
    }
}

#Preview {
    CompanyInfoListView(dataService: MockDataService())
}
extension CompanyInfoListView {
    
    var list: some View {
        VStack{
            Button(action: {
                masterDataManager.seePublicCompanyView = true
            }, label: {
                HStack{
                    Spacer()
                    Text("Company Profile")
                    Spacer()
                }
                .modifier(HeaderModifier())
            })
            Button(action: {
                
                    masterDataManager.seePublicCompanyView = false
            }, label: {
                HStack{
                    Spacer()
                    Text("Company Information")
                    Spacer()
                }
                .modifier(HeaderModifier())
            })
        }
    }
}
