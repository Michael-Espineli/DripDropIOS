//
//  IconModifiers.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/2/25.
//
import SwiftUI
struct SearchIconModifer:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color.white)
            .padding(8)
            .background(Color.poolBlue)
            .cornerRadius(5)
    }
}
struct FilterIconModifer:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color.white)
            .padding(8)
            .background(Color.orange)
            .cornerRadius(5)
    }
}
struct PlusIconModifer:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color.white)
            .padding(8)
            .background(Color.poolGreen)
            .cornerRadius(5)
    }
}
