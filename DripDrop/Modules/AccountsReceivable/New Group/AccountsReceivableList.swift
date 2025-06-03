//
//  AccountsReceivableList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct AccountsReceivableList: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM : AccountingViewModel

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AccountingViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
        }
        .navigationTitle("Accounts Receivable")
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.getAccountsReceivableInvoices(companyId: company.id)
                } catch {
                   print(error)
                }
            }
        }
    }
}

#Preview {
    AccountsReceivableList(dataService: MockDataService())
}

extension AccountsReceivableList {
    var list: some View {
        ScrollView{
            ForEach(VM.accountsReceivableInvoices){ invoice in
                NavigationLink(value: Route.accountsReceivableDetail(invoice: invoice, dataService: dataService), label: {
                    PaymentCardView(invoice: invoice)
                })
                Divider()
            }
        }
    }
}
