//
//  AccountsReceivableList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct AccountsReceivableList: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var VM : AccountingViewModel

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AccountingViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
        }
        .task{
            if let company = masterDataManager.selectedCompany {
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
                Button(action: {
                    masterDataManager.accountsReceivableInvoice = invoice
                }, label: {
                    PaymentCardView(invoice: invoice)
                })
                Divider()
            }
        }
    }
}
