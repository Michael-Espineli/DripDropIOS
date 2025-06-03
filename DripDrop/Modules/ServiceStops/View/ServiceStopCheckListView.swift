//
//  ServiceStopCheckListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/14/24.
//

import SwiftUI

struct ServiceStopCheckListView: View {
    @State var serviceStop: ServiceStop
    @EnvironmentObject var navigationManager : NavigationStateManager

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var customerVM : CustomerViewModel
    @StateObject var jobVM : JobViewModel

    init(serviceStop:ServiceStop,dataService:any ProductionDataServiceProtocol) {
        _serviceStop = State(wrappedValue: serviceStop )
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))

    }
    var body: some View {
        VStack{
            Text("Check List")
        }
    }
}
