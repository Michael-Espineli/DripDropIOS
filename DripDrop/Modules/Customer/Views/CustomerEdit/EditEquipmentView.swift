//
//  EditEquipmentView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct EditEquipmentView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var equipmentVM : EquipmentViewModel
    @State var equipment : Equipment
    
    init(dataService:any ProductionDataServiceProtocol,equipment:Equipment){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
    }

    @State var category:EquipmentCategory = .pump
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
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    var body: some View {
        VStack{
            ScrollView{
                HStack{
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                            .font(.title)
                    })
                    Spacer()
                    button
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 5, trailing: 10))
                form
                button
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            category = equipment.category
            name = equipment.name
            make = equipment.make
            model = equipment.model
            dateInstalled = equipment.dateInstalled
            status = equipment.status
            notes = equipment.notes
            needsService = equipment.needsService
            lastServiced = equipment.lastServiceDate ?? Date()
            serviceFrequency = equipment.serviceFrequency
            serviceFrequencyEvery = equipment.serviceFrequencyEvery

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
                        text: $name
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Category")
                        .bold(true)
                    Picker("Appearance", selection: $category) {
                        ForEach(EquipmentCategory.allCases,id:\.self) {category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                HStack{
                    Text("Make")
                        .bold(true)
                    TextField(
                        "make",
                        text: $make
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
                        text: $model
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Date Installed")
                        .bold(true)
                    DatePicker(selection: $dateInstalled, displayedComponents: .date) {
                    }
                }
                HStack{
                    Text("Status")
                        .bold(true)
                    Picker("Frequency", selection: $status) {
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
                        text: $notes,
                        axis: .vertical
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
            }
            VStack{
                Toggle(isOn: $needsService, label: {
                    Text("Needs Service")
                })
                if needsService {
                    HStack{
                        Text("Last Serviced")
                            .bold(true)
                        DatePicker(selection: $lastServiced, displayedComponents: .date) {
                        }
                    }
                    HStack{
                        Picker("Every", selection: $serviceFrequencyEvery) {
                            Text("Pick WorkSheet")
                            ForEach(0...100,id:\.self) {
                                Text(String($0)).tag(String($0))
                            }
                        }
                        Picker("Frequency", selection: $serviceFrequency) {
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
                        if let company = masterDataManager.selectedCompany {
                            if !needsService {
                                lastServicedOptional = nil
                                serviceFrequency = nil
                                serviceFrequencyEvery = nil
                                
                            } else {
                                lastServicedOptional = lastServiced
                            }
                            try await equipmentVM.updateEquipmentWithValidation(companyId: company.id,
                                                                                category: category,
                                                                                equipmentId: equipment.id,
                                                                                make: make,
                                                                                model: model,
                                                                                dateInstalled: dateInstalled, status: status,
                                                                                notes: notes, 
                                                                                customerName: equipment.customerName ?? "",
                                                                                customerId:  equipment.customerId,
                                                                                serviceLocationId: equipment.serviceLocationId,
                                                                                bodyOfWaterId: equipment.bodyOfWaterId,
                                                                                name: name,
                                                                                needsService: needsService,
                                                                                lastServiceDate: lastServicedOptional,
                                                                                serviceFrequency: serviceFrequency,
                                                                                serviceFrequencyEvery: serviceFrequencyEvery)
                        category = .filter
                            name = ""

                            make = ""
                            model = ""
                            dateInstalled = Date()
                            status = .operational
                            notes = ""
                            
                            needsService = false
                            lastServiced = Date()
                            lastServicedOptional = Date()

                            serviceFrequency = ""
                            serviceFrequencyEvery = ""

                        }
                        
                    } catch {
                        print("Error")
                    }
                }
            }, label: {
                Text("Submit")
            })
        }
    }
}
