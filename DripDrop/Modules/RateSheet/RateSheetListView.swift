//
//  RateSheetListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import SwiftUI

struct RateSheetListView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())

    @State var rateSheets:[RateSheet]
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                list
            }
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await settingsVM.getWorkOrderTemplates(companyId: company.id)

                } catch {
                    print(error)
                }
            }
        }
    }

}

struct RateSheetListView_Previews: PreviewProvider {
    static var previews: some View {
        RateSheetListView(rateSheets: [])
    }
}
extension RateSheetListView {
    var list: some View {
        VStack{
            ForEach(settingsVM.jobTemplates){ tempalte in
                RateSheetCardView(rateSheets: rateSheets, jobTemplate: tempalte)
            }
        }
    }
}
