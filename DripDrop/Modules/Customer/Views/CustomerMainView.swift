//
//  CustomerMainView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import SwiftUI

struct CustomerMainView: View {
    @EnvironmentObject var dataService: ProductionDataService

    var body: some View {
        ZStack{
            CustomerListView(dataService: dataService)
        }
    }
}

