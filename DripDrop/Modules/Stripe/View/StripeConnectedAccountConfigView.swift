//
//  StripeConnectedAccountConfigView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/15/25.
//

import SwiftUI
import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class StripeConnectedAccountConfigViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct StripeConnectedAccountConfigView: View {
    
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: StripeConnectedAccountConfigViewModel(dataService: dataService))
    }
    @StateObject private var VM : StripeConnectedAccountConfigViewModel

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("StripeConnectedAccountConfigView")

            }
        }
    }
}

#Preview {
    StripeConnectedAccountConfigView(dataService: MockDataService())
}
