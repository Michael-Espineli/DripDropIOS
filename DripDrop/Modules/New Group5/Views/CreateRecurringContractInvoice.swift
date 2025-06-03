//
//  CreateRecurringContractInvoice.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

@MainActor
final class CreateRecurringContractInvoiceViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    func onLoad(companyId: String) async throws {
        
    }
}

struct CreateRecurringContractInvoice: View {
    @StateObject var VM : CreateRecurringContractInvoiceViewModel

    init(dataService:any ProductionDataServiceProtocol,recurringLaborContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: CreateRecurringContractInvoiceViewModel(dataService: dataService))
        _recurringLaborContract = State(wrappedValue: recurringLaborContract)
    }
    
    @State var recurringLaborContract: ReccuringLaborContract
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

//#Preview {
//    CreateRecurringContractInvoice()
//}
