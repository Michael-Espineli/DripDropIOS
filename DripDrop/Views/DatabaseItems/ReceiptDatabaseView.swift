//
//  ReceiptDatabaseView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/22/23.
//

import SwiftUI

@MainActor
struct ReceiptDatabaseView: View{
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var viewModel : ReceiptDatabaseViewModel

    init(dataService: any ProductionDataServiceProtocol){
        _viewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
    }
    var body: some View{
        ReceiptDatabaseListView(dataService: dataService)
        .navigationTitle("Database Items")
    }
}



