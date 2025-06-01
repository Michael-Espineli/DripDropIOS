//
//  AssociatedBusinessesPickerView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

@MainActor
final class BuisnessViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct AssociatedBusinessesPickerView: View {
    @StateObject var VM : BuisnessViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
        self._business = business
    }
    @Binding var business : 
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

//#Preview {
//    AssociatedBusinessesPickerView()
//}
