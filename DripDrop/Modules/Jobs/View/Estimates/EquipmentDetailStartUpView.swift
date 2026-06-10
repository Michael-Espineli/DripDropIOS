//
//  EquipmentDetailStartUpView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/29/24.
//

import SwiftUI

struct EquipmentDetailStartUpView: View {
    let dataService: any ProductionDataServiceProtocol
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
                                    text: Binding(
                                        get: { equipment.make },
                                        set: {
                                            equipment.make = $0
                                            equipment.makeId = ""
                                            equipment.modelId = ""
                                            equipment.universalEquipmentId = ""
                                            equipment.manualPdfLink = ""
                                        }
                                    )
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
                                    text: Binding(
                                        get: { equipment.model },
                                        set: {
                                            equipment.model = $0
                                            equipment.modelId = ""
                                            equipment.universalEquipmentId = ""
                                            equipment.manualPdfLink = ""
                                        }
                                    )
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            EquipmentCatalogSelectionControl(
                                dataService: dataService,
                                category: $equipment.type,
                                typeId: $equipment.typeId,
                                make: $equipment.make,
                                makeId: $equipment.makeId,
                                model: $equipment.model,
                                modelId: $equipment.modelId,
                                universalEquipmentId: $equipment.universalEquipmentId,
                                manualPdfLink: $equipment.manualPdfLink,
                                name: $equipment.name
                            )
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
                            Toggle(isOn: $equipment.needsService, label: {
                                Text("Needs Regular Service")
                            })
                            if equipment.needsService {
                                HStack{
                                    Text("Last Serviced")
                                        .bold(true)
                                    DatePicker(
                                        selection: optionalDateBinding($equipment.lastServiceDate),
                                        displayedComponents: .date
                                    ) {
                                    }
                                }
                                HStack{
                                    Picker("Every", selection: optionalIntBinding($equipment.serviceFrequency, defaultValue: 1)) {
                                        ForEach(1...100,id:\.self) {
                                            Text(String($0)).tag($0)
                                        }
                                    }
                                    Picker("Frequency", selection: optionalFrequencyBinding($equipment.serviceFrequencyEvery)) {
                                        ForEach(EquipmentFrequency.allCases) { frequency in
                                            Text(frequency.rawValue).tag(frequency)
                                        }
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

private extension EquipmentDetailStartUpView {
    func optionalDateBinding(_ value: Binding<Date?>) -> Binding<Date> {
        Binding(
            get: { value.wrappedValue ?? Date() },
            set: { value.wrappedValue = $0 }
        )
    }

    func optionalIntBinding(_ value: Binding<Int?>, defaultValue: Int) -> Binding<Int> {
        Binding(
            get: { value.wrappedValue ?? defaultValue },
            set: { value.wrappedValue = $0 }
        )
    }

    func optionalFrequencyBinding(_ value: Binding<EquipmentFrequency?>) -> Binding<EquipmentFrequency> {
        Binding(
            get: { value.wrappedValue ?? .monthly },
            set: { value.wrappedValue = $0 }
        )
    }
}
