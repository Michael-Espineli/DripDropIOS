//
//  TextFieldModifiers.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI
struct TextFieldModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.poolBlack)
            .padding(4)
            .padding(.horizontal, 4)
            .background(Color.poolWhite)
            .cornerRadius(3)
            .fontDesign(.monospaced)
    }
}

struct PlainTextFieldModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.poolBlack)
            .padding(4)
            .padding(.horizontal, 4)
            .background(Color.poolWhite)
            .cornerRadius(3)
            .padding(1)
            .background(Color.poolBlack)
            .cornerRadius(4)
            .fontDesign(.monospaced)
    }
}
struct SearchTextFieldModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .textFieldStyle(PlainTextFieldStyle())
            .font(.headline)
            .padding(8)
            .padding(.horizontal, 8)
            .foregroundColor(Color.poolBlack)
            .background(Color.poolWhite)
            .clipShape(.capsule)
            .foregroundColor(Color.black)
            .frame(maxWidth: .infinity)
            .fontDesign(.monospaced)
            .padding(1)
            .background(Color.poolBlack)
            .clipShape(.capsule)
    }
}
 
