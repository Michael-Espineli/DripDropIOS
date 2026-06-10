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
                                    Text(material.rawValue).tag(material.rawValue)
                                }
                            })
                            Spacer()
                        }
                        HStack{
                            Text("Shape")
                                .bold(true)
                            Picker("Shape", selection: optionalStringBinding($BOW.shape)) {
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
                        HStack(alignment: .top){
                            Text("Notes")
                                .bold(true)

                            TextField("Notes", text: optionalStringBinding($BOW.notes), axis: .vertical)
                                .lineLimit(2...5)
                                .padding(5)
                                .background(Color.white)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(5)
                                .padding(5)
                        }
                        if showDimensions {
                            VStack{
                                dimensionRow(title: "Length 1", text: dimensionBinding($BOW.length, index: 0))
                                dimensionRow(title: "Length 2", text: dimensionBinding($BOW.length, index: 1))
                                dimensionRow(title: "Depth 1", text: dimensionBinding($BOW.depth, index: 0))
                                dimensionRow(title: "Depth 2", text: dimensionBinding($BOW.depth, index: 1))
                                dimensionRow(title: "Width 1", text: dimensionBinding($BOW.width, index: 0))
                                dimensionRow(title: "Width 2", text: dimensionBinding($BOW.width, index: 1))
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

private extension BodyOfWaterDetailStartUpView {
    func optionalStringBinding(_ value: Binding<String?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue ?? "" },
            set: { value.wrappedValue = $0 }
        )
    }

    func dimensionBinding(_ values: Binding<[String]?>, index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let dimensions = values.wrappedValue, dimensions.indices.contains(index) else {
                    return ""
                }

                return dimensions[index]
            },
            set: { newValue in
                var dimensions = values.wrappedValue ?? []

                while dimensions.count <= index {
                    dimensions.append("")
                }

                dimensions[index] = newValue
                values.wrappedValue = dimensions
            }
        )
    }

    func dimensionRow(title: String, text: Binding<String>) -> some View {
        HStack{
            Text(title)
                .bold(true)

            TextField(title, text: text)
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
        }
    }
}
