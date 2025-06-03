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

struct ImageDisplayPopUp: View {
    var urlString:String
    //image display Variables
    @State private var showPDFSheet:Bool = false
    @State private var showJPEGSheet:Bool = false

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
            ZStack{
                if urlString.contains(".pdf"){
                    Button(action: {
                        showPDFSheet.toggle()
                    }, label: {
                        ZStack{
                            if let url = URL(string: urlString){
                                
                                PDFSnapshotView(pdfUrl: url)
                                    .frame(maxWidth: 150,maxHeight:150)
                                    .cornerRadius(8)
                            }
                        }
                   
                    })
                    .sheet(isPresented: $showPDFSheet, content: {
                        if let url = URL(string: urlString){
                            PDFDisplayPopUp(pdfUrl: url)
                        }
                    })
                } else if urlString.contains(".jpeg"){
                    Button(action: {
                        showJPEGSheet.toggle()
                    }, label: {
                        ZStack{
                            if let url = URL(string: urlString){
                                
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
                                    }                            }
                        }
                        .frame(maxWidth: 150,maxHeight:150)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                    })
                    .sheet(isPresented: $showJPEGSheet, content: {
                        if let url = URL(string: urlString){
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
                    })
                } else {
                    Button(action: {
                        showJPEGSheet.toggle()
                    }, label: {
                        ZStack{
                            if let url = URL(string: urlString){
                                
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
                                    }                            }
                        }
                        .frame(maxWidth: 150,maxHeight:150)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                    })
                    .sheet(isPresented: $showJPEGSheet, content: {
                        if let url = URL(string: urlString){
                            
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
                    })
                }
            }
        .padding()
    }
}
