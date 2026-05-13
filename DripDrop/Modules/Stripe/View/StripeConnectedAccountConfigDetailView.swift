//
//  StripeConnectedAccountConfigDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/15/25.
//
import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class StripeConnectedAccountConfigDetailViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct StripeConnectedAccountConfigDetailView: View {
    
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: StripeConnectedAccountConfigDetailViewModel(dataService: dataService))
    }
    @StateObject private var VM : StripeConnectedAccountConfigDetailViewModel

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
    StripeConnectedAccountConfigDetailView(dataService: MockDataService())
}
