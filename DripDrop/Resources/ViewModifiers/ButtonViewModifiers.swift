//
//  ButtonViewModifiers.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/26/23.
//

import Foundation
import SwiftUI

// MARK: - Dismiss / Delete

struct DismissButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.poolRed)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.poolRed.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct DeleteButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.poolRed)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.poolRed.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct DismissButtonTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.subheadline.weight(.semibold))
    }
}

// MARK: - Edit

struct EditButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.poolBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.poolBlue.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct EditButtonTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.subheadline.weight(.semibold))
    }
}

// MARK: - Calendar

struct CalendarButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.15))
            )
    }
}

struct CalendarButtonTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
            .font(.subheadline.weight(.medium))
    }
}

// MARK: - List Cards

struct ListButtonModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.poolBlack : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .foregroundColor(Color.basicFontText)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Cards

struct BasicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.poolBlack)
            )
            .foregroundColor(Color.poolWhite)
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

struct HeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.darkGray)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

struct ListButtonTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
            .font(.subheadline)
    }
}

// MARK: - Standard Buttons

struct BasicButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.poolBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.poolBlue.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct MockButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.pink.opacity(0.8))
            .foregroundColor(.black)
            .cornerRadius(12)
    }
}

struct SubmitButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(Color.poolGreen)
            .foregroundColor(Color.poolWhite)
            .cornerRadius(14)
            .shadow(color: Color.poolGreen.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

struct InvertedSubmitButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.listColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.poolGreen, lineWidth: 2)
            )
            .cornerRadius(12)
            .foregroundColor(Color.poolGreen)
    }
}

struct UploadButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.teal)
            .foregroundColor(.black)
            .cornerRadius(12)
            .shadow(color: Color.teal.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct AddButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.poolBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.poolBlue.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct CustomerCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.9))
            )
            .foregroundColor(.white)
            .shadow(color: Color.orange.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

struct YellowButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.realYellow)
            .foregroundColor(.black)
            .cornerRadius(12)
    }
}

struct OrangeButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.orange)
            .foregroundColor(.black)
            .cornerRadius(12)
    }
}

struct BlueButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.poolBlue)
            .foregroundColor(Color.poolWhite)
            .cornerRadius(12)
            .shadow(color: Color.poolBlue.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct GreenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green)
            )
            .foregroundColor(.white)
            .shadow(color: Color.green.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

struct BlueTagModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.poolBlue)
            .clipShape(Capsule())
            .foregroundColor(.white)
    }
}

struct RedLinkModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote.weight(.medium))
            .padding(4)
            .foregroundColor(Color.poolRed)
    }
}

struct FadedGreenButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.poolGreen.opacity(0.4))
            .cornerRadius(12)
            .foregroundColor(.black)
    }
}

struct OutLineButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
            )
            .cornerRadius(12)
    }
}

/*
struct DismissButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolRed)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)

    }
}
struct DeleteButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolRed)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)

    }
}
struct DismissButtonTextModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.white)


    }
}
struct EditButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct EditButtonTextModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.white)
    }
}
struct CalendarButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .background(Color.red)
            .cornerRadius(5)
    }
}
struct CalendarButtonTextModifier:ViewModifier{
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
    }
}
struct ListButtonModifier:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
//            .background(Color.poolGray) // I am trying new color schemes
            .background(Color.gray.opacity(0.5))
            .cornerRadius(4)
            .foregroundColor(Color.basicFontText)
            .fontDesign(.monospaced)
    }
}
struct BasicCardModifier:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlack)
            .cornerRadius(4)
            .foregroundColor(Color.poolWhite)
            .fontDesign(.monospaced)
    }
}
struct HeaderModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.darkGray)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct ListButtonTextModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
    }
}
struct BasicButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct MockButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.pink)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct SubmitButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolGreen)
            .cornerRadius(4)
            .foregroundColor(Color.poolWhite)
            .fontDesign(.monospaced)
    }
}
struct InvertedSubmitButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.listColor)
            .cornerRadius(4)
            .padding(1)
            .background(Color.poolGreen)
            .cornerRadius(5)
            .foregroundColor(Color.poolBlack)
            .fontDesign(.monospaced)
    }
}
struct UploadButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.teal)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct AddButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct CustomerCardModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.orange)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}

struct YellowButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.realYellow)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct OrangeButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.orange)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct BlueButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.poolWhite)
            .fontDesign(.monospaced)
    }
}
struct GreenCardModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.green)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct BlueTagModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(Color.poolBlue )
            .clipShape(Capsule())
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct RedLinkModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .padding(3)
            .foregroundColor(Color.poolRed)
            .fontDesign(.monospaced)
    }
}
struct FadedGreenButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolGreen.opacity(0.5))
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}

struct OutLineButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(1)
            .background(Color.black)
            .cornerRadius(5)
    }
}
*/
