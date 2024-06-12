//
//  TechRateSheet.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct TechRateSheet: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var settingsVM = SettingsViewModel()
    @StateObject var companyUserVM = CompanyUserViewModel()
    let tech:DBUser
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
            if let company = masterDataManager.selectedCompany {
                do {
                    isLoading = true
                    try await settingsVM.getWorkOrderTemplates(companyId: company.id)
                    try await companyUserVM.getCompanyUserByDBUserId(companyId: company.id, userId: tech.id)
                    if let companyUser = companyUserVM.companyUser {
                        print("Comapny \(String(describing: company.name)) - compayUserId \(companyUser.id)")
                        try await companyUserVM.getAllRateSheetByCompanyUserId(companyId: company.id, companyUserId: companyUser.id)
                    }
                    isLoading = false
                } catch {
                    print(error)
                }
            }
        }
    }
    
}

struct TechRateSheet_Previews: PreviewProvider {
    static var previews: some View {
        TechRateSheet(tech: DBUser(id: "",exp: 0))
    }
}

extension TechRateSheet {
    var rateSheet: some View {
            VStack{
                ForEach(settingsVM.jobTemplates){ tempalte in
                    RateSheetCardView(rateSheets: companyUserVM.rateSheetList, jobTemplate: tempalte)
                }
            }
        
        .padding(5)
    }
}
