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
    var text2 : String?

    let iconName : String

    var body: some View {
//        Rectangle()
//            .fill(color)
//            .frame(width: 100, height: 125)
//            .cornerRadius(8)
        Image("grayback")
            .frame(width: 100, height: 125)
            .cornerRadius(8)
            .overlay(
                    Image(systemName: iconName)
                        .font(.largeTitle)
                        .padding(.top,10)
                    ,alignment: .top

            )
            .overlay(
                ZStack{
                    VStack{
                        Text(text)
                            .font(.footnote)
                            .foregroundColor(textColor)
                            .lineLimit(2,reservesSpace: true)
                        if let text2 {
                            Text(text2)
                                .font(.footnote)
                                .foregroundColor(textColor)
                                .lineLimit(1,reservesSpace: true)
                        }
                    }
                }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(
                        LinearGradient(colors: [
                            footer.opacity(0.0),
                            footer.opacity(0.6)
                        ],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .cornerRadius(8)
                ,alignment: .bottomLeading
            )
    }
}

struct SquareSnapShot_Previews: PreviewProvider {
    static var previews: some View {
        SquareSnapShot(color: Color.poolBlue, footer: Color.gray,textColor: Color.white, text: "Something", iconName: "heart.text.square.fill")
    }
}
