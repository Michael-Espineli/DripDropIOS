//
//  ContractorsListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BuisnessesListView: View {
    @StateObject var VM : BuisnessListViewModel
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: BuisnessListViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
        }
    }
}

#Preview {
    BuisnessesListView(dataService: MockDataService())
}
extension BuisnessesListView {
    var list: some View {
        ScrollView{
            Text("Buisnesses")
            Divider()
            ForEach(VM.buisnesses){ buisness in
                BuisnessCardView(buisness: buisness)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
