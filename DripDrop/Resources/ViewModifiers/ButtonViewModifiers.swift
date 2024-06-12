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
            .padding(8)
            .background(Color.poolRed)
            .cornerRadius(8)
            .foregroundColor(Color.white)

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
            .background(Color.poolBlue)
            .cornerRadius(5)

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
    func body(content: Content) -> some View {
        content
            .padding(5)
            .background(Color.white)
            .cornerRadius(5)
            .shadow(color: Color.basicFontText, radius: 5)
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
            .padding(8)
            .background(Color.poolBlue)
            .cornerRadius(8)
            .foregroundColor(Color.white)
    }
}
