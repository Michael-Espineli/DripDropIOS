//
//  AccountsPayableList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct AccountsPayableList: View {
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
        .navigationTitle("Accounts Payable List")
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.getAccountsPaymentInvoices(companyId: company.id)
                } catch {
                   print(error)
                }
            }
        }
    }
}

#Preview {
    AccountsPayableList(dataService: ProductionDataService())
}

extension AccountsPayableList {
    var list: some View {
        ScrollView{
            ForEach(VM.accountsPayableInvoices){ invoice in
                Button(action: {
                    
                }, label: {
                    PaymentCardView(invoice: invoice)
                })
                Divider()
            }
        }
    }
}
