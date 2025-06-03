//
//  BuisnessContracts.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/25.
//

import SwiftUI

struct BuisnessContracts: View {
    @EnvironmentObject var dataService : ProductionDataService
    @State var selectedScreen : String = "One Time"
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                Picker("Type", selection: $selectedScreen) {
                    Text("One Time").tag("One Time")
                    Text("Recurring").tag("Recurring")
                }
                .pickerStyle(.segmented)
                if selectedScreen == "One Time" {
                    LaborContractListView(dataService: dataService)
                } else {
                    RecurringLaborContractListView(dataService: dataService)
                }
            }
        }
    }
}

#Preview {
    BuisnessContracts()
}
