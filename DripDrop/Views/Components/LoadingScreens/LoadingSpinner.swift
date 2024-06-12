//
//  LoadingSpinner.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

struct LoadingSpinner: View {
    @State var degreesRotating = 0.0
    @State var expansion:CGFloat = 1
    @State var expansion2:CGFloat = 1
    @State var expansion3:CGFloat = 1
    @State var expansion4:CGFloat = 1
    @State var expansion5:CGFloat = 1
    @State var expansion6:CGFloat = 1
    @State var expansion7:CGFloat = 1
    @State var expansion8:CGFloat = 1

    var body: some View {
        ZStack{
            Circle()
                .fill(Color.pink)
                .frame(width: 30,height: 30)
                .offset(x: 0*expansion, y: -50*expansion)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.red)
                .frame(width: 30,height: 30)
                .offset(x: 35*expansion2, y: -35*expansion2)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.orange)
                .frame(width: 30,height: 30)
                .offset(x: 50*expansion3, y: 0)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.yellow)
                .frame(width: 30,height: 30)
                .offset(x: 35*expansion4, y: 35*expansion4)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.green)
                .frame(width: 30,height: 30)
                .offset(x: 0, y: 50*expansion5)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.teal)
                .frame(width: 30,height: 30)
                .offset(x: -35*expansion6, y: 35*expansion6)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.blue)
                .frame(width: 30,height: 30)
                .offset(x: -50*expansion7, y:0)
                .rotationEffect(.degrees(degreesRotating))
            Circle()
                .fill(Color.purple)
                .frame(width: 30,height: 30)
                .offset(x: -35*expansion8, y: -35*expansion8)
                .rotationEffect(.degrees(degreesRotating))
        }
        .onAppear {
             withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                     degreesRotating += 360.0
                 }
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: true)) {
                expansion += 2

                }
            withAnimation(.linear(duration: 1.025).repeatForever(autoreverses: true)) {
                expansion2 += 2
                }
            withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: true)) {
                expansion3 += 2
                }
            withAnimation(.linear(duration: 1.075).repeatForever(autoreverses: true)) {
                expansion4 += 2
                }
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: true)) {
                expansion5 += 2
                }
            withAnimation(.linear(duration: 1.125).repeatForever(autoreverses: true)) {
                expansion6 += 2
                }
            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: true)) {
                expansion7 += 2
                }
            withAnimation(.linear(duration: 1.175).repeatForever(autoreverses: true)) {
                expansion8 += 2
                }
         }
    }
}

#Preview {
    LoadingSpinner()
}
struct Tear: View {
    var body: some View {
        ZStack{
            Circle()
            Rectangle()
                .frame(width: 10,height: 2)
        }
    }
}
