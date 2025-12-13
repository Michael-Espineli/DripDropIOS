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
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _AuthVM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: CompanySettingsViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                
            }
        }
    }
}

#Preview {
    StripeConnectedAccountConfigView()
}
