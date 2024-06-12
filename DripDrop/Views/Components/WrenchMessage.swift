//
//  WrenchMessage.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct WrenchMessage: View {
    var body: some View {
        ZStack{
            Circle()
                .fill(Color.poolGreen)
                .frame(width: 40, height: 40)
            Image(systemName: "bubble.left.fill")
                .foregroundColor(Color.listColor)
                .font(.system(size: 22))
                .offset(y: 2)

            Image(systemName: "wrench.adjustable.fill")
                .foregroundColor(Color.poolGreen)
                .font(.system(size: 10))
        }
    }
}

struct WrenchMessage_Previews: PreviewProvider {
    static var previews: some View {
        WrenchMessage()
    }
}
