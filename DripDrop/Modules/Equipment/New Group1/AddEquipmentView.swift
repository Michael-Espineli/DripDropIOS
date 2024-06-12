//
//  AddEquipmentView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct AddEquipmentView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var customerVM : CustomerViewModel

    @State var bodyOfWater : BodyOfWater
    
    init(dataService:any ProductionDataServiceProtocol,bodyOfWater:BodyOfWater){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _bodyOfWater = State(wrappedValue: bodyOfWater)
    }

    @State var category:EquipmentCategory = .filter
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

    var body: some View {
        VStack{
            ScrollView{
                form
                button
            }
            .padding()
        }
    }
}

extension AddEquipmentView {
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
                    Picker("Status", selection: $status) {
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
                    Text("Needs Regular Service")
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
                            Text("Every")
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
                            //DEVELOPER: THIS WAS THE LAZY WAY TO DO THIS MAKE ALL BODIES OF WATER HAVE A CUSTOMER NAME AS WELL
                            try await customerVM.getCustomer(companyId: company.id, customerId: bodyOfWater.customerId)
                            guard let customer  = customerVM.customer else {
                                throw FireBaseRead.unableToRead
                            }
                            let fullName = customer.firstName + " " + customer.lastName
                            try await equipmentVM.uploadEquipmentWithValidation(
                                companyId: company.id,
                                category: category,
                                make: make,
                                model: model,
                                dateInstalled: dateInstalled,
                                status: status,
                                notes: notes,
                                customerName: fullName,
                                customerId:  bodyOfWater.customerId,
                                serviceLocationId: bodyOfWater.serviceLocationId,
                                bodyOfWaterId: bodyOfWater.id,
                                name: name,
                                needsService: needsService,
                                lastServiceDate: lastServicedOptional,
                                serviceFrequency: serviceFrequency,
                                serviceFrequencyEvery: serviceFrequencyEvery
                            )
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
            },
                   label: {
                Text("Submit")
            })
        }
    }
}
