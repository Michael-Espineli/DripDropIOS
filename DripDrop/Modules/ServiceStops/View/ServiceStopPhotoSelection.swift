//
//  ServiceStopPhotoSelection.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/18/24.
//

import SwiftUI
import PhotosUI
struct ServiceStopPhotoSelection: View {
    @State var showPhotoSelectionOptions:Bool = false
    
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State var image: UIImage?
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    if let selectedImage{
                                   Image(uiImage: selectedImage)
                                       .resizable()
                                       .scaledToFit()
                    } else {
                        Button(action: {
                            showCamera = true
                            print("add New Photo")
                        }, label: {
                            Image(systemName: "photo.fill")
                                .resizable()
                                .frame(width: 100)
                                .scaledToFit()
                            
                                .foregroundColor(Color.blue)
                        })
                    }
                     
                }
                Spacer()
            }
           icons
        }
    }
}

struct ServiceStopPhotoSelection_Previews: PreviewProvider {
    static var previews: some View {
        ServiceStopPhotoSelection()
    }
}
extension ServiceStopPhotoSelection {
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    if showPhotoSelectionOptions {
                        Button(action: {
                            print("Add Album Selection Logic")
                        }, label: {
                          
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "photo.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.yellow)
                            }
                        })
                        Button(action: {
                            showCamera = true
                            print("Add Camera Logic")
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "camera.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        })
                        .sheet(isPresented: $showCamera) {
                                      accessCameraView(selectedImage: self.$selectedImage)
                                  }
                    }
                    Button(action: {
                        showPhotoSelectionOptions.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: showPhotoSelectionOptions ? "xmark.circle.fill" : "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(showPhotoSelectionOptions ? Color.red : Color.poolGreen)
                        }
                    
                    })
                }
            }
            .padding(20)
        }
        .padding(20)
    }
}
