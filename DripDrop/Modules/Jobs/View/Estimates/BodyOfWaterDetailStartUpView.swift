//
//  BodyOfWaterDetailStartUpView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/29/24.
//

import SwiftUI

struct BodyOfWaterDetailStartUpView: View {
    @Binding var bodiesOfWater:[BodyOfWater]
    @Binding var selectedBodyOfWater:BodyOfWater
    @Binding var equipmentList:[Equipment]
    @Binding var photos:[String:[DripDropImage]]

    @State var shapes:[String] = ["Square","Rectangle","Kidney","Circular"]
    @State var material:BodyOfWaterMaterial = .plaster
    @State var name:String = ""

    @State var gallons:String = "0"
    @State var length1:String = ""
    @State var depth1:String = ""
    @State var width1:String = ""
    
    @State var length2:String = ""
    @State var depth2:String = ""
    @State var width2:String = ""
    @State var selectedPhotos:[DripDropImage] = []
    @State var shape:String = ""
    @State var showDimensions:Bool = false
    
    var body: some View {
        VStack{
            ForEach($bodiesOfWater){ $BOW in
                if BOW.id == selectedBodyOfWater.id {
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                equipmentList.removeAll(where: {$0.bodyOfWaterId == selectedBodyOfWater.id})
                                bodiesOfWater.removeAll(where: {$0.id == selectedBodyOfWater.id})
                                
                            }, label: {
                                Text("Delete")
                                    .modifier(DeleteButtonModifier())
                            })
                        }
                        HStack{
                            Text("Name: ")
                                .bold(true)
                            
                            TextField("Name", text: $BOW.name, prompt: Text("Name"), axis: .vertical)
                                .padding(5)
                                .background(Color.white)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(5)
                                .padding(5)
                        }
                        HStack{
                            Text("Material")
                                .bold(true)
                            Picker("Pool Material", selection: $BOW.material, content: {
                                ForEach(BodyOfWaterMaterial.allCases,id:\.self){ material in
                                    Text(material.rawValue).tag(material)
                                }
                            })
                            Spacer()
                        }
                        HStack{
                            Text("Shape")
                                .bold(true)
                            Picker("Shape", selection: $BOW.shape) {
                                ForEach(shapes,id: \.self){ shape in
                                    Text(shape).tag(shape)
                                }
                            }
                            Spacer()
                        }
                        
                        HStack{
                            Text("Gallons: ")
                                .bold(true)
                            
                            TextField("Gallons", text: $BOW.gallons, prompt: Text("Gallons"), axis: .vertical)
                                .padding(5)
                                .background(Color.white)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(5)
                                .padding(5)
                            Button(action: {
                                showDimensions.toggle()
                            }, label: {
                                Text("Add Dimensions")
                                    .modifier(AddButtonModifier())
                            })
                        }
                        if showDimensions {
                            if shape == "Kidney" {
                                VStack{
                                    HStack{
                                        Text("length 1")
                                            .bold(true)
                                        TextField(
                                            "length 1",
                                            text: $length1
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("length 2")
                                            .bold(true)
                                        TextField(
                                            "length 2",
                                            text: $length2
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("depth 1")
                                            .bold(true)
                                        TextField(
                                            "depth 1",
                                            text: $depth1
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("depth 2")
                                            .bold(true)
                                        TextField(
                                            "depth 2",
                                            text: $depth2
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("width 1")
                                            .bold(true)
                                        TextField(
                                            "width 1",
                                            text: $width1
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("width 2")
                                            .bold(true)
                                        TextField(
                                            "width 2",
                                            text: $width2
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    
                                }
                            }
                        }
                        PhotoContentView(selectedImages: $selectedPhotos)
                    }
                }
            }
        }
        .onAppear(perform: {
            print("")

            print("On Appear selectedEquipmentId")
            selectedPhotos = []
            if let preselectedPhotos = photos[selectedBodyOfWater.id] {
                selectedPhotos = preselectedPhotos
                print(preselectedPhotos)
            } else {
                selectedPhotos = []
            }
        })
        .onChange(of: selectedBodyOfWater, perform: { BOW in
            print("")
            selectedPhotos = []
            print("Change of selected Equipment Id")
            if let preselectedPhotos = photos[BOW.id] {
                selectedPhotos = preselectedPhotos
                print("selectedPhotos")

                print(selectedPhotos)

            } else {
                selectedPhotos = []
                print("selectedPhotos")
                print(selectedPhotos)

            }
        })
        .onChange(of: selectedPhotos, perform: { images in
            print("")
            print("Change Of Selected Photos")
            print(images)
            if !images.isEmpty {
                photos[selectedBodyOfWater.id] = images
            }
        })
    }
}

//#Preview {
//    BodyOfWaterDetailStartUpView()
//}
