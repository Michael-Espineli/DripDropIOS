import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/michaelespineli/Desktop/DripDrop/DripDrop/Modules/New Group5/Views/RecurringLaborContractInvoiceCardView.swift", line: 1)
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
            Text(__designTimeString("#16496_0", fallback: "Contract Info"))
            HStack{
                Text("Last Billed: \(shortDate(date: VM.lastBilled))")
                
                    Spacer()
                Text(String(VM.weeksBetween))
            }
            .lineLimit(__designTimeInteger("#16496_1", fallback: 1))
            HStack{
                Text("Total: \(Double(VM.total)/__designTimeInteger("#16496_2", fallback: 100), format: .currency(code: __designTimeString("#16496_3", fallback: "USD")).precision(.fractionLength(__designTimeInteger("#16496_4", fallback: 2))))")
                Spacer()
                Text("Weekly: \(Double(VM.weeklyTotal)/__designTimeInteger("#16496_5", fallback: 100), format: .currency(code: __designTimeString("#16496_6", fallback: "USD")).precision(.fractionLength(__designTimeInteger("#16496_7", fallback: 2))))")
            }
            .lineLimit(__designTimeInteger("#16496_8", fallback: 1))
        }
        .modifier(ListButtonModifier())
        .padding(__designTimeInteger("#16496_9", fallback: 8))
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
        recurringContract: MockDataService.mockRecurringLaborContracts[__designTimeInteger("#16496_10", fallback: 0)]
    )
    .environmentObject(masterDataManager)

}
