//
//  ManagementTablesView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/5/24.
//

import SwiftUI
@MainActor
final class ManagementTablesViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct ManagementTablesView: View {
    @StateObject var VM : ManagementTablesViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: ManagementTablesViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            tableView
        }
    }
}

#Preview {
    ManagementTablesView(dataService: MockDataService())
}

extension ManagementTablesView {
    var tableView: some View {
        VStack{
            
        }
    }
}
