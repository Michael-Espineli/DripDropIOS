//
//  MangeStripeSubscriptionsDetailView.swift
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
final class MangeStripeSubscriptionsDetailViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct MangeStripeSubscriptionsDetailView: View {
    
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: MangeStripeSubscriptionsDetailViewModel(dataService: dataService))
    }
    @StateObject private var VM : MangeStripeSubscriptionsDetailViewModel

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
    MangeStripeSubscriptionsDetailView(dataService: MockDataService())
}

