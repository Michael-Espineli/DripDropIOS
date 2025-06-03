//
//  ServiceLocationStartUpViewInField.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/14/24.
//

import SwiftUI

struct ServiceLocationStartUpViewInField: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var vm : JobTemplateViewModel
    @StateObject var VM : ServiceLocationStartUpViewModel

    init(dataService: any ProductionDataServiceProtocol,customerId:String,serviceLocationId:String,serviceStop:ServiceStop) {
        _vm = StateObject(wrappedValue: JobTemplateViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: ServiceLocationStartUpViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _serviceStop = State(wrappedValue: serviceStop)

    }
    @State var customerId: String
    @State var serviceLocationId: String
    @State var serviceStop: ServiceStop
    
    @State var selectedBOW:BodyOfWater = BodyOfWater(
        id: UUID().uuidString,
        name: "Main Pool",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        notes: "",
        shape: "",
        length: [],
        depth: [],
        width: [],
        lastFilled: Date()
    )
    @State var bodyOfWaterList:[BodyOfWater] = []
    
    //Equipment
    @State var equipmentList:[Equipment] = []
    @State var selectedEquipmentId:String = ""
    @State var selectedEquipmentCategory:EquipmentCategory? = nil
    
    //Images
    @State var bodyOfWaterImages:[String:[DripDropImage]] = [:]
    @State var equipmentImages:[String:[DripDropImage]] = [:]
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            bodyOfWaterStartUp
                            equipmentStartUp
                        }
                        .padding(.horizontal,16)
                        
                    }, header: {
                        HStack{
                            bodyOfWaterPicker
                            
                            button
                        }
                        .padding(.vertical,5)
                        .padding(.horizontal,8)
                        .padding(.top,24)
                        .background(Color.listColor)
                        
                    })
                })
                .clipped()
            }
            .ignoresSafeArea()
            if VM.isLoading {
                ProgressView()
                    .padding(8)
                    .background(Color.darkGray)
                    .cornerRadius(8)
            }
            
        }
        .onAppear(perform: {
            bodyOfWaterList.append(selectedBOW)
            equipmentList.append(
                contentsOf: [
                    Equipment(
                        id: UUID().uuidString,
                        name: "Main Pump",
                        category: .pump,
                        make: "",
                        model: "",
                        dateInstalled: Date(),
                        status: .operational,
                        needsService: false,
                        cleanFilterPressure: 15,
                        currentPressure: 20,
                        lastServiceDate: Date(),
                        serviceFrequency: "",
                        serviceFrequencyEvery: "",
                        nextServiceDate: Date(),
                        notes: "",
                        customerName: "Developer Customer Name",
                        customerId: customerId,
                        serviceLocationId: serviceLocationId,
                        bodyOfWaterId: selectedBOW.id,
                        isActive: true
                    ),
                    Equipment(
                        id: UUID().uuidString,
                        name: "Main Filter",
                        category: .filter,
                        make: "",
                        model: "",
                        dateInstalled: Date(),
                        status: .operational,
                        needsService: false,
                        cleanFilterPressure: 15,
                        currentPressure: 20,
                        lastServiceDate: Date(),
                        serviceFrequency: "",
                        serviceFrequencyEvery: "",
                        nextServiceDate: Date(),
                        notes: "",
                        customerName: "Developer Customer Name",
                        customerId: customerId,
                        serviceLocationId: serviceLocationId,
                        bodyOfWaterId: selectedBOW.id,
                        isActive: true
                    )
                ]
            )
        })
    }
}

//#Preview {
//    ServiceLocationStartUpView(dataService: MockDataService(), serviceLocation: MockDataService.mockServiceLocation)
//}
extension ServiceLocationStartUpViewInField {
    var button: some View {
        HStack{
            Button(action: {
                Task{
                    if VM.isLoading {
                    } else {
                        do {
                            if let company = masterDataManager.currentCompany {
                                
                                if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                                    try await VM.createLocation(
                                        companyId: serviceStop.contractedCompanyId,
                                        customerId: customerId,
                                        serviceLocationId: serviceLocationId,
                                        bodyOfWaterList: bodyOfWaterList,
                                        equipmentList: equipmentList,
                                        bodyOfWaterImages: bodyOfWaterImages,
                                        equipmentImages: equipmentImages
                                    )
                                
                                }
                                
                                    try await VM.createLocation(
                                        companyId: company.id,
                                        customerId: customerId,
                                        serviceLocationId: serviceLocationId,
                                        bodyOfWaterList: bodyOfWaterList,
                                        equipmentList: equipmentList,
                                        bodyOfWaterImages: bodyOfWaterImages,
                                        equipmentImages: equipmentImages
                                    )
                            } else {
                                print("no Company")
                            }
                            print("Successful")
                        } catch {
                            print("error")
                            print(error)
                        }
                    }
                }
            },
                   label: {
                Text("Save")
                    .modifier(SubmitButtonModifier())
            })
        }
    }
    var bodyOfWaterPicker: some View {
        VStack{
            HStack{
                Text("Bodies Of Water")
                Spacer()
            }
            HStack{
                Rectangle()
                    .frame(width: 150, height: 3)
                Spacer()
            }
            
            ScrollView(.horizontal){
                HStack(spacing:16){
                    Button(action: {
                        let name = "Pool" + " " + String(bodyOfWaterList.count + 1)
                        let id = UUID().uuidString
                        bodyOfWaterList.append(
                            BodyOfWater(
                                id: id,
                                name: name,
                                gallons: "",
                                material: "",
                                customerId: "",
                                serviceLocationId: "",
                                notes: "",
                                shape: "",
                                length: [],
                                depth: [],
                                width: [],
                                lastFilled: Date()
                            ))
                        selectedBOW = bodyOfWaterList.first(where: {$0.id == id})! //DEVELOPER, I know i explicitly unwrapped but it should never fail.
                        equipmentList.append(
                            contentsOf: [
                                Equipment(
                                    id: UUID().uuidString,
                                    name: "Main Pump",
                                    category: .pump,
                                    make: "",
                                    model: "",
                                    dateInstalled: Date(),
                                    status: .operational,
                                    needsService: false,
                                    cleanFilterPressure: 15,
                                    currentPressure: 20,
                                    lastServiceDate: Date(),
                                    serviceFrequency: "",
                                    serviceFrequencyEvery: "",
                                    nextServiceDate: Date(),
                                    notes: "",
                                    customerName: "Developer Customer Name",
                                    customerId: customerId,
                                    serviceLocationId: serviceLocationId,
                                    bodyOfWaterId: selectedBOW.id,
                                    isActive: true
                                ),
                                Equipment(
                                    id: UUID().uuidString,
                                    name: "Main Filter",
                                    category: .filter,
                                    make: "",
                                    model: "",
                                    dateInstalled: Date(),
                                    status: .operational,
                                    needsService: false,
                                    cleanFilterPressure: 15,
                                    currentPressure: 20,
                                    lastServiceDate: Date(),
                                    serviceFrequency: "",
                                    serviceFrequencyEvery: "",
                                    nextServiceDate: Date(),
                                    notes: "",
                                    customerName: "Developer Customer Name",
                                    customerId: customerId,
                                    serviceLocationId: serviceLocationId,
                                    bodyOfWaterId: selectedBOW.id,
                                    isActive: true
                                )
                            ]
                        )
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                    ForEach(bodyOfWaterList){ BOW in
                        Button(action: {
                            selectedBOW = BOW
                            
                            if let selectedEquipmentCategory, let first = equipmentList.filter({$0.id == BOW.id}).filter({$0.category == selectedEquipmentCategory}).first{
                                selectedEquipmentId = first.id
                                print("Selected Equipment Id true")
                            } else {
                                print("Selected Equipment Id is nil")
                                selectedEquipmentId = ""
                            }
                            
                        }, label: {
                            Text("\(BOW.name)")
                                .padding(8)
                                .background(selectedBOW.id == BOW.id ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                        
                    }
                }
            }
        }
    }
    var bodyOfWaterStartUp: some View {
        VStack{
            
            BodyOfWaterDetailStartUpView(bodiesOfWater: $bodyOfWaterList, selectedBodyOfWater: $selectedBOW, equipmentList: $equipmentList, photos: $bodyOfWaterImages)
        }
    }
    var equipmentStartUp: some View {
        VStack{
            Text("Equipment Start Up")
                .font(.headline)
            Rectangle()
                .frame(height: 4)
            ForEach(EquipmentCategory.allCases,id:\.self){ category in
                Section(content: {
                    if selectedEquipmentId != "" {
                        if let selectedEquipmentCategory {
                            if selectedEquipmentCategory == category {
                                EquipmentDetailStartUpView(
                                    equipmentList: $equipmentList,
                                    selectedEquipmentId: $selectedEquipmentId,
                                    photos:$equipmentImages
                                )
                            }
                        }
                    }
                },
                        header: {
                    VStack{
                        HStack{
                            Text(category.rawValue)
                            Spacer()
                        }
                        HStack{
                            Rectangle()
                                .frame(width:50,height: 1)
                            Spacer()
                        }
                        ScrollView(.horizontal){
                            HStack{
                                Button(action: {
                                    selectedEquipmentId = ""
                                    let newId = UUID().uuidString
                                    let name = category.rawValue + " " + String(equipmentList.filter({$0.bodyOfWaterId == selectedBOW.id}).filter({$0.category == category}).count + 1)
                                    equipmentList.append(
                                        Equipment(
                                            id: newId,
                                            name: name,
                                            category: category,
                                            make: "",
                                            model: "",
                                            dateInstalled: Date(),
                                            status: .operational,
                                            needsService: false,
                                            notes: "",
                                            customerName: "Developer Customer Name",
                                            customerId: customerId,
                                            serviceLocationId: serviceLocationId,
                                            bodyOfWaterId: selectedBOW.id,
                                            isActive: true
                                        )
                                    )
                                    selectedEquipmentId = newId
                                    selectedEquipmentCategory = category
                                },label: {
                                    Image(systemName: "plus")
                                        .foregroundColor(Color.white)
                                        .padding(8)
                                        .background(Color.poolBlue)
                                        .cornerRadius(8)
                                })
                                ForEach(equipmentList.filter({$0.bodyOfWaterId == selectedBOW.id}).filter({$0.category == category})) { equipment in
                                    Button(action: {
                                        if selectedEquipmentId == equipment.id {
                                            selectedEquipmentId = ""
                                            selectedEquipmentCategory = nil
                                        } else {
                                            selectedEquipmentId = equipment.id
                                            selectedEquipmentCategory = category
                                        }
                                    }, label: {
                                        Text("\(equipment.name)")
                                            .padding(8)
                                            .background(selectedEquipmentId == equipment.id ? Color.poolBlue : Color.darkGray)
                                            .foregroundColor(Color.white)
                                            .cornerRadius(8)
                                    })
                                }
                            }
                        }
                    }
                })
                Rectangle()
                    .frame(height: 2)
            }
        }
    }
}
