//
//  CompanyUserRateSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/15/24.
//


import SwiftUI

struct CompanyUserRateSheet: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    @StateObject var companyUserVM = CompanyUserViewModel()
    let tech:CompanyUser
    @State var isLoading:Bool = true
    var body: some View {
        ScrollView{
            Text("Rate Sheet")
                .font(.headline)
            Divider()
            if isLoading {
                ProgressView()
            } else {
                rateSheet
            }
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    isLoading = true
                        try await settingsVM.getWorkOrderTemplates(companyId: company.id)
                        try await companyUserVM.getAllRateSheetByCompanyUserId(companyId: company.id, companyUserId: tech.id)
                    
                    isLoading = false
                } catch {
                    print(error)
                }
            }
        }
    }
}

struct CompanyUserRateSheet_Previews: PreviewProvider {
    static var previews: some View {
        CompanyUserRateSheet(tech: CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor))
    }
}

extension CompanyUserRateSheet {
    var rateSheet: some View {
            VStack{
                ForEach(settingsVM.jobTemplates){ tempalte in
                    RateSheetCardView(rateSheets: companyUserVM.rateSheetList, jobTemplate: tempalte)
                    Divider()
                }
            }
        .padding(8)
    }
}

