//
//  RecurringLaborContractInvoiceCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/1/25.
//

import SwiftUI

struct RecurringLaborContractInvoiceCardView: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : RecurringLaborContractInvoiceCardViewModel

    init(dataService:any ProductionDataServiceProtocol,recurringContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: RecurringLaborContractInvoiceCardViewModel(dataService: dataService))
        _recurringContract = State(wrappedValue: recurringContract)
    }
    @State var recurringContract: ReccuringLaborContract

    var body: some View {
        VStack{
            HStack{
                Text("Last Billed: \(shortDate(date: VM.lastBilled))")
                
                    Spacer()
            }
            .lineLimit(1)
            HStack{
                Text("Total: \(Double(VM.total)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                Spacer()
            }
            .lineLimit(1)
            .font(.footnote)
        }
        .modifier(ListButtonModifier())
        .padding(8)
        .task {
            if let currentCompany = masterDataManager.currentCompany{
                do{
                    try await VM.onLoad(companyId: currentCompany.id, contractId: recurringContract.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    @StateObject var masterDataManager : MasterDataManager = MasterDataManager()
    RecurringLaborContractInvoiceCardView(
        dataService: MockDataService(),
        recurringContract: MockDataService.mockRecurringLaborContracts[0]
    )
    .environmentObject(masterDataManager)

}
