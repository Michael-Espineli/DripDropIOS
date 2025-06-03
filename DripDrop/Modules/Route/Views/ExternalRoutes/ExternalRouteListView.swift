//
//  ExternalRouteListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/29/24.
//

import SwiftUI

struct ExternalRouteListView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: ExternalRouteListViewModel(dataService: dataService))
    }
    
    @Environment(\.locale) var locale
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : ExternalRouteListViewModel
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
        }
        .navigationTitle("Contracted External Routes")
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId:currentCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ExternalRouteListView(dataService: MockDataService())
}

extension ExternalRouteListView {
    var list: some View {
        ScrollView{
            ForEach(VM.days,id:\.self){ day in
                if let externalRouteList = VM.externalRouteDisplayDayList[day] {
                    ExternalRouteDayView(
                        dataService: dataService,
                        day: day,
                        externalRouteStopList: externalRouteList
                    )
                    .padding(.vertical,10)
                }
            }
       
        }
    }
}
