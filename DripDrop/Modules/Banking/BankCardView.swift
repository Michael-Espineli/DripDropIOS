//
//  BankCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/30/24.
//

import SwiftUI

struct BankCardView: View {
    let bank:Bank
    var body: some View {
        VStack{
            Text("\(bank.name)")
                .font(.title)
            Text("\(bank.accountNumber)")
                .font(.footnote)
            Rectangle()
                .frame(height: 1)
            Text("\(bank.balance*100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                .font(.footnote)
        }
        .background(Color.gray)
        .cornerRadius(16)
        .padding(16)
    }
}

#Preview {
    BankCardView(bank: Bank(name: "Wells Fargo", accountNumber: "12345678", balance: 123_456_78))
}
