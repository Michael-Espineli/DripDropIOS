//
//  ReuseableFields.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/4/26.
//

import SwiftUI
import Foundation

// MARK: - PhoneNumberField
/// A text field specialized for phone numbers.
/// - Formats input as (XXX) XXX-XXXX while typing (US style)
/// - Uses the phone pad keyboard and content type .telephoneNumber
public struct PhoneNumberField: View {
    @Binding var text: String
    var title: String
    var showsValidation: Bool

    @State private var isEditing: Bool = false

    public init(_ title: String = "Phone", text: Binding<String>, showsValidation: Bool = true) {
        self._text = text
        self.title = title
        self.showsValidation = showsValidation
    }

    private var isValid: Bool {
        // Consider valid if 10 digits
        digitsOnly.count == 10
    }

    private var digitsOnly: String {
        text.filter { $0.isNumber }
    }

    private func formatUSPhone(_ digits: String) -> String {
        var d = String(digits.prefix(10))
        let count = d.count
        if count == 0 { return "" }
        if count < 4 {
            return "(" + d
        } else if count < 7 {
            let area = d.prefix(3)
            let rest = d.dropFirst(3)
            return "(\(area)) \(rest)"
        } else {
            let area = d.prefix(3)
            let prefix = d.dropFirst(3).prefix(3)
            let line = d.dropFirst(6)
            return "(\(area)) \(prefix)-\(line)"
        }
    }

    public var body: some View {
        HStack(spacing: 8) {
            TextField(title, text: Binding(
                get: { text },
                set: { newValue in
                    // Keep only digits and reformat
                    let digits = newValue.filter { $0.isNumber }
                    text = formatUSPhone(digits)
                }
            ))
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .onTapGesture { isEditing = true }

            if showsValidation, !text.isEmpty {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(isValid ? .green : .orange)
                    .accessibilityLabel(isValid ? "Valid phone number" : "Invalid phone number")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - EmailField
/// A text field specialized for email addresses.
/// - Uses .emailAddress keyboard
/// - Performs a lightweight validity check
public struct EmailField: View {
    @Binding var text: String
    var title: String
    var showsValidation: Bool

    public init(_ title: String = "Email", text: Binding<String>, showsValidation: Bool = true) {
        self._text = text
        self.title = title
        self.showsValidation = showsValidation
    }

    private var isValid: Bool {
        // Simple heuristic: contains one "@" and a dot after it, with no spaces
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let atRange = trimmed.range(of: "@") else { return false }
        let domain = trimmed[atRange.upperBound...]
        return !trimmed.contains(" ") && domain.contains(".") && atRange.lowerBound != trimmed.startIndex && domain.first != "."
    }

    public var body: some View {
        HStack(spacing: 8) {
            TextField(title, text: $text)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if showsValidation, !text.isEmpty {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(isValid ? .green : .orange)
                    .accessibilityLabel(isValid ? "Valid email" : "Invalid email")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - NumberField
/// A plain numeric field for integer or decimal input.
/// - Displays numeric keyboard
/// - Optional formatter to control presentation
public struct NumberField: View {
    @Binding var text: String
    var title: String
    var allowsDecimal: Bool

    public init(_ title: String, text: Binding<String>, allowsDecimal: Bool = true) {
        self._text = text
        self.title = title
        self.allowsDecimal = allowsDecimal
    }

    public var body: some View {
        TextField(title, text: Binding(
            get: { text },
            set: { newValue in
                let filtered = newValue.filter { ch in
                    if ch.isNumber { return true }
                    if allowsDecimal && ch == "." { return !text.contains(".") }
                    if ch == "-" { return text.isEmpty }
                    return false
                }
                text = filtered
            }
        ))
        .keyboardType(allowsDecimal ? .decimalPad : .numberPad)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
    }
    private var digitsOnly: String {
            text.filter { $0.isNumber }
    }
}


// MARK: - MilesField
/// A numeric field tailored for distances in miles.
/// - Shows a trailing "mi" label
/// - Accepts integers or decimals
public struct MilesField: View {
    @Binding var text: String
    var title: String

    public init(_ title: String = "Miles", text: Binding<String>) {
        self._text = text
        self.title = title
    }

    public var body: some View {
        HStack {
            NumberField(title, text: $text, allowsDecimal: true)
            Text("mi")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews
//#Preview("PhoneNumberField") {
//    @Previewable @State var phone = ""
//    Form { PhoneNumberField(text: $phone) }
//}
//
//#Preview("EmailField") {
//    @Previewable @State var email = ""
//    Form { EmailField(text: $email) }
//}
//
//#Preview("NumberField Int") {
//    @Previewable @State var value = ""
//    Form { NumberField("Quantity", text: $value, allowsDecimal: false) }
//}
//
//#Preview("MilesField") {
//    @Previewable @State var miles = ""
//    Form { MilesField(text: $miles) }
//}
