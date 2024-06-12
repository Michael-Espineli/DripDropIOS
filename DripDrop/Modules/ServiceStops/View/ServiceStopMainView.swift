//
//  ServiceStopMainView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct ServiceStopMainView: View {
    @EnvironmentObject var dataService : ProductionDataService

    var body: some View {
        ZStack{
            ServiceStopListView(dataService: dataService)

        }
    }
}



