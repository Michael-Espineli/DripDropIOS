//
//  Images.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//

import SwiftUI
struct ImageDisplay: View {
    var url:URL
    //image display Variables
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0

        @State private var currentScale: CGFloat = 1.0
        @GestureState private var zoomFactor: CGFloat = 2.0

        var magnification: some Gesture {
            return MagnificationGesture()
                .updating($zoomFactor) { value, scale, transaction in
                    withAnimation {
                        scale = value
                    }
                }
                .onChanged { value in
                    withAnimation {
                        currentScale += value
                    }
                }
                .onEnded { value in
                    // do nothing
                }
        }


    var body: some View {
        ScrollView{
            ZStack{
                Color.gray
                    AsyncImage(url: url){ image in
                        image
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(currentZoom + totalZoom)
                            .gesture(magnification)
                    } placeholder: {
                        Image(systemName:"doc")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.basicFontText)
                    }
                
            }

        }
        .padding()
    }
}

