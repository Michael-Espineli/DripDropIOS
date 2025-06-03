//
//  EditVehicalView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI

struct EditVehicalView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    init(dataService:any ProductionDataServiceProtocol,vehical:Vehical){
        _vehical = State(initialValue: vehical)
    }
    //Received
    @State var vehical : Vehical? = nil
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
//
//#Preview {
//    EditVehicalView()
//}
