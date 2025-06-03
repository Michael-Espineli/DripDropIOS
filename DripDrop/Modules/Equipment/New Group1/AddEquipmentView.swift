    //
    //  AddEquipmentView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //

import SwiftUI
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class AddEquipmentViewModel:ObservableObject{
    private var dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    @Published private(set) var customer: Customer? = nil
    @Published private(set) var equipmentTypes : [UniversalEquipmentType] = []
    @Published var selectedEquipmentType: UniversalEquipmentType? = nil {
        didSet {
            onChangeOfSelectedType()
        }
    }
    @Published private(set) var equipmentmakes : [UniversalEquipmentMake] = []
    @Published var selectedEquipmentMake: UniversalEquipmentMake? = nil {
        didSet {
            onChangeOfSelectedMake()
        }
    }
    @Published private(set) var universalEquipmentList : [UniversalEquipment] = []
    @Published var selectedUniversalEquipment: UniversalEquipment? = nil
    
    @Published var category:EquipmentCategory = .filter
    @Published var name:String = ""
    @Published var showSelectEquipment:Bool = false

    @Published var make:String = ""
    @Published var model:String = ""
    @Published var dateInstalled:Date = Date()
    @Published var status:EquipmentStatus = .operational
    @Published var notes:String = ""
    
    @Published var needsService:Bool = false
    @Published var lastServiced:Date = Date()
    @State var lastServicedOptional:Date? = Date()
    
    @Published var serviceFrequency:String? = ""
    @Published var serviceFrequencyEvery:String? = ""
    
    func onLoad(companyId:String,bodyOfWater:BodyOfWater) async throws {
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: bodyOfWater.customerId)
        self.equipmentTypes = try await dataService.getUniversalEquipmentTypes()
    }
    func onChangeOfSelectedType() {
        Task{
            if let selectedEquipmentType {
                do {
                    self.equipmentmakes = try await dataService.getUniversalEquipmentBrandsByType(type: selectedEquipmentType)
                } catch {
                    print(error)
                }
            }
        }
    }
    func onChangeOfSelectedMake() {
        Task{
            if let selectedEquipmentMake, let selectedEquipmentType {
                do {
                    self.universalEquipmentList =  try await dataService.getUniversalEquipmentByTypeAndBrand(type: selectedEquipmentType, make: selectedEquipmentMake)
                } catch {
                    print(error)
                }
            }
        }
    }
    func addNewEquipment(companyId:String,bodyOfWater:BodyOfWater) async throws {
        let bodyOfWaterId = "comp_bow_" + UUID().uuidString
        if let customer {
            let fullName = customer.firstName + " " + customer.lastName
            let equipment = Equipment(
                id: bodyOfWaterId,
                name: name,
                category: category,
                make: make,
                model: model,
                dateInstalled: dateInstalled,
                status: status,
                needsService: needsService,
                //                cleanFilterPressure: T##Int?,
                //                currentPressure: T##Int?,
                lastServiceDate: lastServiced,
                serviceFrequency: serviceFrequency,
                serviceFrequencyEvery: serviceFrequencyEvery,
                nextServiceDate: getNextServiceDate(
                    lastServiceDate: lastServiced,
                    every: serviceFrequencyEvery,
                    frequency: serviceFrequency
                ),
                notes: notes,
                customerName: fullName,
                customerId: customer.id,
                serviceLocationId: bodyOfWater.serviceLocationId,
                bodyOfWaterId: bodyOfWater.id, 
                isActive: true
            )
            try await dataService.addNewEquipmentWithParts(
                companyId: companyId,
                equipment: equipment
            )
        }
        self.name = ""
        self.make = ""
        self.model = ""
        self.dateInstalled = Date()
        self.notes = ""
        self.status = .operational
        self.needsService = false
        self.lastServiced = Date()
        self.lastServicedOptional = Date()
    }
}
struct AddEquipmentView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : AddEquipmentViewModel
    
    @State var bodyOfWater : BodyOfWater
    
    init(dataService:any ProductionDataServiceProtocol,bodyOfWater:BodyOfWater){
        _VM = StateObject(wrappedValue: AddEquipmentViewModel(dataService: dataService))
        _bodyOfWater = State(wrappedValue: bodyOfWater)
    }
    var body: some View {
        VStack{
            ScrollView{
                form
                button
            }
            .padding()
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, bodyOfWater: bodyOfWater)
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension AddEquipmentView {
    var form: some View {
        VStack{
            Text("Add New Equipment")
            VStack{
                HStack{
                    Text("Name")
                        .bold(true)
                    TextField(
                        "Name",
                        text: $VM.name
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                Rectangle()
                    .frame(height: 1)
                Button(action: {
                    VM.showSelectEquipment.toggle()
                }, label: {
                    Text("Tester Equipment Search")
                })
                .sheet(isPresented: $VM.showSelectEquipment, content: {
                    equipmentSelector
                })
                Rectangle()
                    .frame(height: 1)
                HStack{
                    Text("Category")
                        .bold(true)
                    Picker("Appearance", selection: $VM.category) {
                        ForEach(EquipmentCategory.allCases,id:\.self) { category in
                            Text("\(category.rawValue)").tag(category)
                        }
                    }
                }
                HStack{
                    Text("Make")
                        .bold(true)
                    TextField(
                        "make",
                        text: $VM.make
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
                        text: $VM.model
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Date Installed")
                        .bold(true)
                    DatePicker(selection: $VM.dateInstalled, displayedComponents: .date) {
                    }
                }
                HStack{
                    Text("Status")
                        .bold(true)
                    Picker("Status", selection: $VM.status) {
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
                        text: $VM.notes,
                        axis: .vertical
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
            }
            VStack{
                Toggle(isOn: $VM.needsService, label: {
                    Text("Needs Regular Service")
                })
                if VM.needsService {
                    HStack{
                        Text("Last Serviced")
                            .bold(true)
                        DatePicker(selection: $VM.lastServiced, displayedComponents: .date) {
                        }
                    }
                    HStack{
                        Picker("Every", selection: $VM.serviceFrequencyEvery) {
                            Text("Every")
                            ForEach(0...100,id:\.self) {
                                Text(String($0)).tag(String($0))
                            }
                        }
                        Picker("Frequency", selection: $VM.serviceFrequency) {
                            Text("Day").tag("Day")
                            Text("Week").tag("Week")
                            Text("Month").tag("Month")
                            Text("Year").tag("Year")
                        }
                    }
                }
            }
        }
    }
    var button: some View {
        VStack{
            Button(action: {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await VM.addNewEquipment(companyId: company.id, bodyOfWater: bodyOfWater)
                        }
                    } catch {
                        print("Error")
                    }
                }
            },
                   label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())
                
            })
        }
    }
    var equipmentSelector: some View {
        ScrollView{
            VStack{
                if let selectedType = VM.selectedEquipmentType {
                    if let selectedMake = VM.selectedEquipmentMake {
                        HStack{
                            Button(action: {
                                VM.selectedEquipmentMake = nil
                            }, label: {
                                Text("Back")
                                    .modifier(DismissButtonModifier())
                            })
                            Spacer()
                        }
                        HStack{
                            Text("Type : ")
                                .font(.headline)
                            Spacer()
                            Text("\(selectedType.name)")
                        }
                        HStack{
                            Text("Make : ")
                                .font(.headline)
                            Spacer()
                            Text("\(selectedMake.name)")
                        }
                        Text("Equipment List - \(VM.universalEquipmentList.count)")
                        
                        ForEach(VM.universalEquipmentList){ equipment in
                            Button(action: {
                                VM.selectedUniversalEquipment = equipment
                            }, label: {
                                Text(equipment.model)
                                    .modifier(ListButtonModifier())
                            })
                            .padding(.vertical,5)
                        }
                    } else {
                        HStack{
                            Button(action: {
                                VM.selectedEquipmentType = nil
                            }, label: {
                                Text("Back")
                                    .modifier(DismissButtonModifier())
                            })
                            Spacer()
                        }
                        HStack{
                            Text("Type : ")
                                .font(.headline)
                            Spacer()
                            Text("\(selectedType.name)")

                        }
                        Text("Equipment Makes - \(VM.equipmentmakes.count)")
                        
                        ForEach(VM.equipmentmakes){ make in
                            Button(action: {
                                VM.selectedEquipmentMake = make
                            }, label: {
                                Text(make.name)
                                    .modifier(ListButtonModifier())
                            })
                            .padding(.vertical,5)
                        }
                    }
                } else {
                    Text("Equipment Types - \(VM.equipmentTypes.count)")
                    ForEach(VM.equipmentTypes){ type in
                        Button(action: {
                            VM.selectedEquipmentType = type
                        }, label: {
                            Text(type.name)
                                .modifier(ListButtonModifier())
                        })
                        .padding(.vertical,5)
                    }
                }
            }
            .padding(8)
        }
    }
}
