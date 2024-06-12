//
//  SquareSnapShot.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI

struct SquareSnapShot: View {
    let color : Color
    let footer : Color
    let textColor : Color
    let text : String
    let iconName : String

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 100, height: 100)
            .overlay(
                    Image(systemName: iconName)
                        .font(.largeTitle)
                        .padding(.top,10)
                    ,alignment: .top

            )
            .overlay(
                ZStack{
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(textColor)
                        .lineLimit(2,reservesSpace: true)
                }
   
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(colors: [
                            footer.opacity(0.0),
                            footer.opacity(0.6)
                        ],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                ,alignment: .bottomLeading
            )
    }
}

struct SquareSnapShot_Previews: PreviewProvider {
    static var previews: some View {
        SquareSnapShot(color: Color.poolBlue, footer: Color.gray,textColor: Color.white, text: "Something", iconName: "heart.text.square.fill")
    }
}
