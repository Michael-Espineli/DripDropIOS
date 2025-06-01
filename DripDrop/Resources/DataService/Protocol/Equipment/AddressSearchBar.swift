//
//  AddressSearchBar.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/5/24.
//

import SwiftUI
@MainActor
final class EditEquipmentViewModel:ObservableObject{
    private var dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
}
struct AddressSearchBar: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    AddressSearchBar()
}
