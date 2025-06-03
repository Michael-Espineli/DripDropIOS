//
//  PerformaceHistoryList.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import SwiftUI

struct PerformaceHistoryList: View {
    @StateObject var performaceReviewVM : PerformaceHistoryViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var receivedCompanyUser:CompanyUser

    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _receivedCompanyUser = State(wrappedValue: companyUser)
        _performaceReviewVM = StateObject(wrappedValue:PerformaceHistoryViewModel(dataService: dataService))
    }
    var body: some View {
        ScrollView{
            Text("Performace History List")
            Rectangle()
                .frame(height: 4)
            ForEach(performaceReviewVM.performaceHistoryList){ performace in
                PerformanceHistoryCardView(performanceHistory: performace)
                Rectangle()
                    .frame(height: 1)
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await performaceReviewVM.getPerformaceReivewByUserId(companyId: company.id, companyUserId: receivedCompanyUser.id)
                } else {
                    print("Company User Error")
                }
            } catch {
                print("Error Getting DetailView")
                print(error)
            }
        }
    }
}

//#Preview {
//    PerformaceHistoryList()
//}
