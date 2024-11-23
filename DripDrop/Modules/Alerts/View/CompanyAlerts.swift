//
//  CompanyAlerts.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import SwiftUI

struct CompanyAlerts: View {
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: CompanyAlertViewModel(dataService: dataService))
    }
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : CompanyAlertViewModel


    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                list
            }
            .padding(8)
        }
        .navigationTitle("Company Alerts")
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.getAlertsByCompany(companyId: selectedCompany.id)
                } catch{
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

#Preview {
    CompanyAlerts(dataService: MockDataService())
}
extension CompanyAlerts {
    var list: some View {
        VStack{
            if !VM.alertList.isEmpty {
                laborContracts
                Rectangle()
                    .frame(height: 1)
            }
        }
    }
    var laborContracts: some View {
        VStack{
            Text("Labor Contracts - \(VM.alertList.count)")
                .fontWeight(.bold)
            Divider()
            ForEach(VM.alertList){ alert in
                DripDropAlertCardSmall(dataService: dataService, alert: alert)
            }
        }
    }
}
