//
//  JobView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/13/23.
//

import SwiftUI

struct JobView: View{
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var viewModel : PurchasesViewModel
    init(dataService: any ProductionDataServiceProtocol){
        _viewModel = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))

    }
    @State private var selected = Set<PurchasedItem.ID>()
    @State private var isPresented = false

    var body: some View{
        ZStack{
            VStack{
                JobListView(dataService: dataService)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

