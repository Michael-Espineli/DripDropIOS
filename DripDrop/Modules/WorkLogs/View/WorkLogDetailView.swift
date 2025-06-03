//
//  WorkLogDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/11/24.
//

import SwiftUI

@MainActor
final class WorkLogDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
}

struct WorkLogDetailView: View {
    init(dataService: any ProductionDataServiceProtocol, workLog:WorkLog){
        
    }
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

//#Preview {
//    WorkLogDetailView()
//}
