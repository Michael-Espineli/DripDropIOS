//
//  EquipmentDetailStartUpView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/29/24.
//

import SwiftUI

struct EquipmentDetailStartUpView: View {
    @Binding var equipmentList:[Equipment]
    @Binding var selectedEquipmentId:String
    @Binding var photos:[String:[DripDropImage]]

    @State var name:String = ""

    @State var make:String = ""
    @State var model:String = ""
    @State var dateInstalled:Date = Date()
    @State var status:EquipmentStatus = .operational
    @State var notes:String = ""
    
    @State var needsService:Bool = false
    @State var lastServiced:Date = Date()
    @State var lastServicedOptional:Date? = Date()

    @State var serviceFrequency:String? = ""
    @State var serviceFrequencyEvery:String? = ""
    @State var images:[UIImage] = []
    @State var selectedPhotos:[DripDropImage] = []

    var body: some View {
        VStack{
            ForEach($equipmentList) { $equipment in
                if equipment.id == selectedEquipmentId {
                    VStack{
                        HStack{
                            Text("Detail")
                                .font(.headline)
                            Text("\(selectedEquipmentId)")
                            Spacer()
                            Button(action: {
                                equipmentList.removeAll(where: {$0.id == selectedEquipmentId})
                            }, label: {
                                Text("Delete")
                                    .modifier(DismissButtonModifier())
                            })
                        }
                        VStack{
                            HStack{
                                Text("Name: ")
                                    .bold(true)
                                TextField(
                                    "Name",
                                    text: $equipment.name
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                Text("Make")
                                    .bold(true)
                                TextField(
                                    "make",
                                    text: $equipment.make
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                Text("Model")
                                    .bold(true)
                                TextField(
                                    "model",
                                    text: $equipment.model
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                Text("Date Installed")
                                    .bold(true)
                                DatePicker(selection: $equipment.dateInstalled, displayedComponents: .date) {
                                }
                            }
                            HStack{
                                Text("Status")
                                    .bold(true)
                                Picker("Status", selection: $equipment.status) {
                                    ForEach(EquipmentStatus.allCases,id:\.self) { category in
                                        Text("\(category.rawValue)").tag(category)
                                    }
                                }
                            }
                            HStack{
                                Text("Notes")
                                    .bold(true)
                                TextField(
                                    "notes",
                                    text: $equipment.notes,
                                    axis: .vertical
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                        }
                        VStack{
                            Toggle(isOn: $needsService, label: {
                                Text("Needs Regular Service")
                            })
                            if needsService {
                                HStack{
                                    Text("Last Serviced")
                                        .bold(true)
                                    DatePicker(selection: $lastServiced, displayedComponents: .date) {
                                    }
                                }
                                .onChange(of: lastServiced, perform: { date in
                                    equipment.lastServiceDate = date
                                })
                                HStack{
                                    Picker("Every", selection: $equipment.serviceFrequencyEvery) {
                                        Text("Every")
                                        ForEach(0...100,id:\.self) {
                                            Text(String($0)).tag(String($0))
                                        }
                                    }
                                    Picker("Frequency", selection: $equipment.serviceFrequency) {
                                        Text("Day").tag("Day")
                                        Text("Week").tag("Week")
                                        Text("Month").tag("Month")
                                        Text("Year").tag("Year")
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
            if let preselectedPhotos = photos[selectedEquipmentId] {
                selectedPhotos = preselectedPhotos
                print(preselectedPhotos)
            } else {
                selectedPhotos = []
            }
        })
        .onChange(of: selectedEquipmentId, perform: { id in
            print("")
            selectedPhotos = []
            print("Change of selected Equipment Id")
            if let preselectedPhotos = photos[id] {
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
                photos[selectedEquipmentId] = images
            }
        })
    }
}

//#Preview {
//    EquipmentDetailStartUpView()
//}
