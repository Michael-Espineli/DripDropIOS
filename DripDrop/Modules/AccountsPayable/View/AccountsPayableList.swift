//
//  AccountsPayableList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct AccountsPayableList: View {
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
            ForEach(VM.accountsReceivableInvoices){ invoice in
                Button(action: {
                    
                }, label: {
                    PaymentCardView(invoice: invoice)
                })
                Divider()
            }
        }
    }
}
