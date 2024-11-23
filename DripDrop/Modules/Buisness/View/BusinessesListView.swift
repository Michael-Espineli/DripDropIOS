//
//  ContractorsListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BuisnessesListView: View {
    @StateObject var VM : BuisnessViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
        }
        .task{
            if let selectedCompany = masterDataManager.selectedCompany {
                do {
                    try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
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
