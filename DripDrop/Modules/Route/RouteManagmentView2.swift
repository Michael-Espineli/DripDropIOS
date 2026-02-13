//
//  RouteManagmentView2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/7/26.
//

import SwiftUI
struct RouteManagmentView: View {

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var VM: RouteBoardViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(
            wrappedValue: RouteBoardViewModel(dataService: dataService)
        )
    }

    private let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack {

                    if VM.isInitialLoading {
                        ProgressView("Loading Routes")
                    } else {
                        dayThenTech
                    }

                }
                .padding(.horizontal, 8)
            }
        }
        .navigationTitle("Routes")

        // Start listeners once
        .task(id: masterDataManager.currentCompany?.id) {
            guard let companyId = masterDataManager.currentCompany?.id else { return }
            VM.start(companyId: companyId)
        }

        // Stop listeners when leaving screen
        .onDisappear {
            VM.stop()
        }

        .refreshable {
            VM.forceRecompute()
        }
    }
}
