//
//  MoneyTextField.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/2/26.
//

import SwiftUI

struct MoneyTextField: View {
    @Binding var cents: Int
    var currencyCode: String = "USD"

    @State private var rawDigits: String = ""
    @FocusState private var isFocused: Bool

    private var formattedValue: String {
        // Convert rawDigits -> cents -> currency string
        let intCents = Int(rawDigits) ?? 0
        let amount = Decimal(intCents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }

    var body: some View {
        TextField("", text: Binding(
            get: { formattedValue },
            set: { newValue in
                // Strip to digits only
                let digits = newValue.compactMap { $0.isNumber ? $0 : nil }
                rawDigits = String(digits)
                // Update binding in cents
                cents = Int(rawDigits) ?? 0
            }
        ))
        .keyboardType(.numberPad)
        .focused($isFocused)
        .onAppear {
            // Initialize rawDigits from initial cents
            rawDigits = String(cents)
        }
        .onChange(of: cents) { newCents in
            // If cents changes externally, reflect in rawDigits
            let newDigits = String(newCents)
            if newDigits != rawDigits {
                rawDigits = newDigits
            }
        }
        .modifier(PlainTextFieldModifier()) // Optional: your existing styling
        .accessibilityLabel("Amount")
        .accessibilityValue(formattedValue)
    }
}
