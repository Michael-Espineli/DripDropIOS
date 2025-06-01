//
//  CompanyRoutingView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/12/24.
//

import SwiftUI
@MainActor
final class CompanyRoutingViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct CompanyRoutingView: View {
    init(dataService: any ProductionDataServiceProtocol) {
        
    }
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    CompanyRoutingView()
}
