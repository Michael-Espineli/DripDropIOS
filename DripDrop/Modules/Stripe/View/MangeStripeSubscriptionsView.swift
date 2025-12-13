//
//  MangeStripeSubscriptionsView.swift
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
final class MangeStripeSubscriptionsViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct MangeStripeSubscriptionsView: View {
    
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: MangeStripeSubscriptionsViewModel(dataService: dataService))
    }
    @StateObject private var VM : MangeStripeSubscriptionsViewModel

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("MangeStripeSubscriptionsView")
            }
        }
    }
}

#Preview {
    StripeConnectedAccountConfigView(dataService: MockDataService())
}

