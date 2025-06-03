//
//  EditEquipmentView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
@MainActor
final class EditEquipmentViewModel:ObservableObject{
    private var dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    @Published var category:EquipmentCategory = .pump
    @Published var name:String = ""

    @Published var make:String = ""
    @Published var model:String = ""
    @Published var dateInstalled:Date = Date()
    @Published var status:EquipmentStatus = .operational
    @Published var notes:String = ""
    
    @Published var needsService:Bool = false
    @Published var lastServiced:Date = Date()
    @Published var lastServicedOptional:Date? = Date()
    @Published var currentPressure:String = ""
    @Published var cleanPressure:String = ""

    @Published var serviceFrequency:String? = ""
    @Published var serviceFrequencyEvery:String? = ""
    @Published var alertMessage:String = ""
    @Published var showAlert:Bool = false
    
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        try await dataService.deleteEquipment(companyId: companyId, equipmentId: equipmentId)
    }
    func updateEquipmentWithValidation(
        companyId : String,
        equipmentId : String,
        equipment : Equipment
    ) async throws {

        if needsService {
//            guard let validatedLastServiceDate = lastServiced else {
//                throw FireBasePublish.unableToPublish
//            }
            guard let validatedServiceFrequency = serviceFrequency else {
                throw FireBasePublish.unableToPublish
            }
            guard let validatedServiceFrequencyEvery = serviceFrequencyEvery else {
                throw FireBasePublish.unableToPublish
            }
            guard let validedNextDate = getNextServiceDate(lastServiceDate: lastServiced, every: serviceFrequencyEvery, frequency: serviceFrequency) else {
                throw FireBasePublish.unableToPublish
            }
            
            if equipment.serviceFrequency != serviceFrequency {
                try dataService.updateEquipmentServiceFrequency(companyId: companyId, equipmentId: equipmentId, serviceFrequency: validatedServiceFrequency)
            }
            if equipment.serviceFrequencyEvery != serviceFrequencyEvery {
                try dataService.updateEquipmentServiceFrequencyEvery(companyId: companyId, equipmentId: equipmentId, serviceFrequencyEvery: validatedServiceFrequencyEvery)
            }
            try dataService.updateEquipmentNextServiceDate(companyId: companyId, equipmentId: equipmentId, nextServiceDate: validedNextDate)
        }
        if equipment.name != name {
            try dataService.updateEquipmentName(companyId: companyId, equipmentId: equipmentId, name: notes)
        }
        if equipment.category != category {
            try dataService.updateEquipmentCategory(companyId: companyId, equipmentId: equipmentId, category: category)
        }
        if equipment.make != make {
            try dataService.updateEquipmentMake(companyId: companyId, equipmentId: equipmentId, make: make)
        }
        if equipment.model != model {
            try dataService.updateEquipmentModel(companyId: companyId, equipmentId: equipmentId, model: model)
        }
        if equipment.status != status {
            try dataService.updateEquipmentStatus(companyId: companyId, equipmentId: equipmentId, status: status)
        }
        if equipment.dateInstalled != dateInstalled {
            try dataService.updateEquipmentDateInstalled(companyId: companyId, equipmentId: equipmentId, dateInstalled: dateInstalled)
        }
        if let pressureInt = Int(cleanPressure) {
            if equipment.cleanFilterPressure != pressureInt {
                try dataService.updateEquipmentCleanFilterPressure(companyId: companyId, equipmentId: equipmentId, cleanFilterPressure: pressureInt)
            }
        }
        if let pressureInt = Int(currentPressure) {
            
            if equipment.currentPressure != pressureInt {
                try dataService.updateEquipmentCurrentPressure(companyId: companyId, equipmentId: equipmentId, currentPressure: pressureInt)
            }
        }
        if equipment.lastServiceDate != lastServiced {
            try dataService.updateEquipmentCleanLastServiceDate(companyId: companyId, equipmentId: equipmentId, lastServiceDate: lastServiced)
        }
        
        if equipment.notes != notes {
            try dataService.updateEquipmentNotes(companyId: companyId, equipmentId: equipmentId, notes: notes)
        }
    }
}
struct EditEquipmentView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : EditEquipmentViewModel
    @State var equipment : Equipment
    
    init(dataService:any ProductionDataServiceProtocol,equipment:Equipment){
        _VM = StateObject(wrappedValue: EditEquipmentViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
    }

    var body: some View {
        VStack{
            ScrollView{
                form
                button
            }
            .padding(8)

        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            VM.category = equipment.category
            VM.name = equipment.name
            VM.make = equipment.make
            VM.model = equipment.model
            VM.dateInstalled = equipment.dateInstalled
            VM.status = equipment.status
            VM.notes = equipment.notes
            VM.needsService = equipment.needsService
            VM.lastServiced = equipment.lastServiceDate ?? Date()
            VM.serviceFrequency = equipment.serviceFrequency
            VM.serviceFrequencyEvery = equipment.serviceFrequencyEvery

        }
    }
}
extension EditEquipmentView {
    var form: some View {
        VStack{
            Text("Form")
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
                HStack{
                    Text("Category")
                        .bold(true)
                    Picker("Appearance", selection: $VM.category) {
                        ForEach(EquipmentCategory.allCases,id:\.self) {category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                HStack{
                    Text("Make")
                        .bold(true)
                    TextField(
                        "Make",
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
                        "Model",
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
                    Picker("Frequency", selection: $VM.status) {
                        Text("Operational").tag("Operational")
                        Text("Needs Repair").tag("Needs Repair")
                        Text("Nonoperational").tag("Nonoperational")
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
                    Text("Needs Service")
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
                            Text("Pick WorkSheet")
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
                            if !VM.needsService {
                                VM.lastServicedOptional = nil
                                VM.serviceFrequency = nil
                                VM.serviceFrequencyEvery = nil
                                
                            } else {
                                VM.lastServicedOptional = VM.lastServiced
                            }
                            try await VM.updateEquipmentWithValidation(companyId: company.id, equipmentId: equipment.id, equipment: equipment)
                        }
                        
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }, label: {
                Text("Save")
                    .modifier(SubmitButtonModifier())

            })
        }
    }
}
