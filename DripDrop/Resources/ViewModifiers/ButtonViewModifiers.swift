//
//  ButtonViewModifiers.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/26/23.
//

import Foundation
import SwiftUI

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
            .background(Color.poolGray)
            .cornerRadius(4)
            .foregroundColor(Color.basicFontText)
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
            .foregroundColor(Color.basicFontText)
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



