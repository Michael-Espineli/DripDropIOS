//
//  View.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import Foundation
import SwiftUI
struct FlippedUpsideDown: ViewModifier {
   func body(content: Content) -> some View {
    content
           .rotationEffect(Angle(radians: .pi))
      .scaleEffect(x: -1, y: 1, anchor: .center)
   }
}
extension View{
   func flippedUpsideDown() -> some View{
     self.modifier(FlippedUpsideDown())
   }
    func navigationBarBackground(_ background: Color = .poolBlue) -> some View {
      return self
        .modifier(ColoredNavigationBar(background: background))
    }
}

extension View {

}

struct ColoredNavigationBar: ViewModifier {
  var background: Color
  
  func body(content: Content) -> some View {
    content
      .toolbarBackground(
        background,
        for: .navigationBar
      )
      .toolbarBackground(.visible, for: .navigationBar)
  }
}
