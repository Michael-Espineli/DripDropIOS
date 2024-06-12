//
//  WaterLevelLoading.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/20/24.
//

import SwiftUI
struct WaterLevelLoading: View {
    @State var animate: Bool = false
    @State var height1:CGFloat = -0.05
    @State var height2:CGFloat = -0.05
    @State var height3:CGFloat = -0.05

    @State var xoffset:CGFloat = 100
    @State var yoffset:CGFloat = 700
    @State var bubbleOffset:CGFloat = 700
    @State var bubbleOffset2:CGFloat = 1400

    var body: some View {
        ZStack{
            Color.poolWhite
            WaterWave(waveHeight: height1, xoffset: 200,yoffset: 0.1)
                .foregroundColor(Color.blue).opacity(0.5)
                .offset(y: yoffset)
            WaterWave(waveHeight: height2, xoffset: 100,yoffset: 0.05)
                .foregroundColor(Color.blue).opacity(0.5)
                .offset(y: yoffset)
            WaterWave(waveHeight: height3, xoffset: 300,yoffset: 0.0)
                .foregroundColor(Color.blue).opacity(0.5)
                .offset(y: yoffset)
            VStack{
                Spacer()
                Text("The Pool App")
                    .font(.title)
                    .foregroundColor(Color.poolWhite)
                    .padding(100)
            }
            bubbles
                .offset(y: bubbleOffset2)
            bubbles2
                .offset(y: bubbleOffset + 50 )
            bubbles3
                .offset(y: bubbleOffset2 + 100 )
            bubbles4
                .offset(y: bubbleOffset + 150 )
            bubbles
                .offset(x:-85,y: bubbleOffset2 + 200)
            bubbles2
                .offset(x:-42,y: bubbleOffset +  250)
            bubbles3
                .offset(x:29,y: bubbleOffset2 - 300)
            bubbles4
                .offset(x:62,y: bubbleOffset + 450)
        }
        .ignoresSafeArea()
        .onAppear{
            withAnimation(Animation.linear(duration: 7).repeatForever(autoreverses: true)) {
                height1 += 0.12
                height2 += 0.03
                height3 += 0.08
                xoffset += -800
            }
            withAnimation(Animation.linear(duration: 7)) {
                yoffset += -600
            }
            withAnimation(Animation.linear(duration: 6)) {
                bubbleOffset += -1400

            }
            withAnimation(Animation.linear(duration: 11)) {
                bubbleOffset2 += -1400

            }
        }
    }
}

#Preview {
    WaterLevelLoading()
}
extension WaterLevelLoading {
    var bubbles: some View {
        ZStack{
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: 80, y: 110)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: 185, y: 205)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: 135, y: 145)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: 255, y: 75)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: 0, y: 195)
            Circle()
                .frame(width: 20, height: 20)
                .offset(x: 0, y: 95)
            Circle()
                .frame(width: 30, height: 30)
                .offset(x: 45, y: 105)
        }
        .foregroundColor(Color.poolWhite.opacity(0.5))
    }
    var bubbles2: some View {
        ZStack{
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: -0, y: 50)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: -20, y: 120)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: -80, y: 40)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: -0, y: 70)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: -50, y: 80)
            Circle()
                .frame(width: 20, height: 20)
                .offset(x: -0, y: 120)
            Circle()
                .frame(width: 30, height: 30)
                .offset(x: -120, y: 10)
        }
        .foregroundColor(Color.poolWhite.opacity(0.5))
    }
    var bubbles3: some View {
        ZStack{
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: 50, y: -0)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: 95, y: -110)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: 205, y: -50)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: 175, y: -20)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: 150, y: -30)
            Circle()
                .frame(width: 20, height: 20)
                .offset(x: 50, y: -85)
            Circle()
                .frame(width: 30, height: 30)
                .offset(x: 100, y: -154)
        }
        .foregroundColor(Color.poolWhite.opacity(0.5))

    }
    var bubbles4: some View {
        ZStack{
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: -10, y: -50)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: -130, y: -20)
            Circle()
                .frame(width: 5, height: 5)
                .offset(x: -40, y: -140)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: -80, y: -70)
            Circle()
                .frame(width: 10, height: 10)
                .offset(x: -60, y: -80)
            Circle()
                .frame(width: 20, height: 20)
                .offset(x: -0, y: -120)
            Circle()
                .frame(width: 30, height: 30)
                .offset(x: -100, y: -10)
        }
        .foregroundColor(Color.poolWhite.opacity(0.5))
    }

}
struct WaterWave:Shape {
    var waveHeight:CGFloat
    var xoffset:CGFloat
    var yoffset:CGFloat

    var animatableData: Double {
        get { waveHeight }
        set { self.waveHeight = newValue }
    }
    var animatableData2: Double {
        get { xoffset }
        set { self.xoffset = newValue }
    }
    var animatableData3: Double {
        get { yoffset }
        set { self.yoffset = newValue }
    }
    func path(in rect:CGRect) -> Path {
        return Path{ path in
            path.move(to: .zero)
            let progressHeight: CGFloat = rect.maxX*yoffset
            let height = waveHeight * rect.height

            for value in stride(from: 0,through: rect.width, by: 2) {

                let x : CGFloat = value
                let sine : CGFloat = sin(Angle(degrees:value + xoffset).radians)
                let y : CGFloat = progressHeight + (height * sine)

                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))

        }
    }
}



#Preview {
    WaterWave(waveHeight: -0.05, xoffset: 0, yoffset: 1)
}
