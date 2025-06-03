//
//  SquareLoading.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 6/8/24.
//


import SwiftUI

struct SquareLoading: View {
    let color : Color
    let footer : Color
    let textColor : Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 100, height: 125)
            .cornerRadius(8)
            .overlay(
                    ProgressView()
                        .font(.largeTitle)
                        .padding(.top,10)
                    ,alignment: .top

            )
            .overlay(
                ZStack{
                    Text("...Loading")
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

struct SquareLoading_Previews: PreviewProvider {
    static var previews: some View {
        SquareLoading(color: Color.poolBlue, footer: Color.gray,textColor: Color.white)
    }
}
struct SquareEmpty: View {
    let color : Color
    let footer : Color
    let textColor : Color
    let text : String
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 100, height: 125)
            .cornerRadius(8)

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
