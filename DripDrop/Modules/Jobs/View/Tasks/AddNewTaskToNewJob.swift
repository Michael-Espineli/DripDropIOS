//
//  AddNewTaskToNewJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import SwiftUI

struct AddNewTaskToNewJob: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    init(dataService:any ProductionDataServiceProtocol,jobId:String,taskTypes:[String],customerId:String,serviceLocationId:String,task){
        _VM = StateObject(wrappedValue: AddNewTaskToJobViewModel(dataService: dataService))

        _jobId = State(wrappedValue: jobId)
        _taskTypes = State(wrappedValue: taskTypes)
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
    }
    
    @StateObject var VM : AddNewTaskToJobViewModel
    @State var jobId:String
    @State var taskTypes:[String]
    @State var customerId:String
    @State var serviceLocationId:String
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            formView
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            do {
                if let currentCompany = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: currentCompany.id,jobId:jobId, serviceLocationId: serviceLocationId)
                }
            } catch {
                print(error)
            }
        }
        .onChange(of: VM.selectedTaskType,
                  perform: {
            taskType in
            Task{
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfSelectedTaskType(
                            companyId: currentCompany.id,
                            customerId: customerId,
                            serviceLocationId: serviceLocationId
                        )
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.contractedRateString, perform: { str in
            let isNumber = VM.checkNumber(numberStr: str)
            if str != "" {
                if !isNumber {
                    VM.contractedRateString = "0"
                }
            }
        })
        .onChange(of: VM.estimatedTimeString, perform: { str in
            let isNumber = VM.checkNumber(numberStr: str)
            if str != "" {
                if !isNumber {
                    VM.estimatedTimeString = "0"
                }
            }
        })
    }
}

//#Preview {
//    AddNewTaskToJob(jobId: "J123456789",taskTypes: [])
//}
extension AddNewTaskToNewJob {
    var formView : some View {
        VStack{
            HStack{
                Text("Name")
                    .bold(true)
                TextField(
                    "Name",
                    text: $VM.name
                )
                .modifier(TextFieldModifier())
            }
            HStack{
                Text("Contracted Rate")
                    .bold(true)
                TextField(
                    "Contracted Rate",
                    text: $VM.contractedRateString
                )
                .modifier(TextFieldModifier())
            }
            HStack{
                Text("Estimated Time")
                    .bold(true)
                TextField(
                    "Estimated Time",
                    text: $VM.estimatedTimeString
                )
                .modifier(ListButtonModifier())
            }
            
            HStack{
                Text("Task Type: ")
                    .bold(true)
                Picker("Task Type", selection: $VM.selectedTaskType) {
                    ForEach(JobTaskType.allCases){ type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Spacer()
            }
            VStack{
                switch VM.selectedTaskType {
                    case .basic, .clean:
                        Text("No Extra Details Needed")
                    case .cleanFilter:
                    Text("Filter Clean \(VM.equipmentList.count)")
                    Picker("Equipment", selection: $VM.selectedEquipmentId) {
                        Text("Select Equipment").tag("")
                        ForEach(VM.equipmentList){ equipment in
                            Text("\(equipment.name)").tag(equipment.id)
                        }
                    }
                    case .emptyWater:
                        Text("Empty Water")
                        Picker("Body Of Water", selection: $VM.selectedBodyOfWaterId) {
                            Text("Select Body Of Water").tag("")
                            ForEach(VM.bodyOfWaterList){ BOW in
                                Text(BOW.name).tag(BOW.id)
                            }
                        }
                    case .fillWater:
                        Text("Fill Water")
                        Picker("Body Of Water", selection: $VM.selectedBodyOfWaterId) {
                            Text("Select Body Of Water").tag("")
                            ForEach(VM.bodyOfWaterList){ BOW in
                                Text(BOW.name).tag(BOW.id)
                            }
                        }
                    case .inspection:
                        Text("Inspection")
                    case .install:
                        Text("Install")
                    
                        Picker("Body Of Water", selection: $VM.selectedBodyOfWaterId) {
                            Text("Select Body Of Water").tag("")
                            ForEach(VM.bodyOfWaterList){ BOW in
                                Text(BOW.name).tag(BOW.id)
                            }
                        }
                        Button(action: {
                            VM.showItemPicker.toggle()
                        }, label: {
                            if VM.dataBaseItem.id == "" {
                                Text("Select Item")
                                    .modifier(BlueButtonModifier())
                            } else {
                                Text(VM.dataBaseItem.name)
                                    .modifier(BlueButtonModifier())
                            }
                        })
                        .sheet(isPresented: $VM.showItemPicker, onDismiss: {
                            
                        }, content: {
                            DataBaseItemPicker(dataService: dataService, DBItem: $VM.dataBaseItem, category: .equipment)
                        })
                    
                        HStack{
                            Text("Quantity")
                                .bold(true)
                            TextField(
                                "Quantity",
                                text: $VM.quantityString
                            )
                            .modifier(TextFieldModifier())
                        }
                    case .remove:
                        Text("Remove")
                        Picker("Equipment", selection: $VM.selectedEquipmentId) {
                            Text("Select Equipment").tag("")
                            ForEach(VM.equipmentList){ equipment in
                                Text("\(equipment.name) - \(equipment.category.rawValue)").tag(equipment.id)
                            }
                        }
                    case .replace:
                        Text("Replace")
                        Picker("Equipment", selection: $VM.selectedEquipmentId) {
                            Text("Select Equipment").tag("")
                            ForEach(VM.equipmentList){ equipment in
                                Text("\(equipment.name) - \(equipment.category.rawValue)").tag(equipment.id)
                            }
                        }
                        Divider()
                        Text("Install")
                        Button(action: {
                            VM.showItemPicker.toggle()
                        }, label: {
                            if VM.dataBaseItem.id == "" {
                                Text("Select Item")
                                    .modifier(BlueButtonModifier())
                            } else {
                                Text(VM.dataBaseItem.name)
                                    .modifier(BlueButtonModifier())
                            }
                        })
                        .sheet(isPresented: $VM.showItemPicker, onDismiss: {
                            
                        }, content: {
                            DataBaseItemPicker(dataService: dataService, DBItem: $VM.dataBaseItem, category: .equipment)
                        })
                        HStack{
                            Text("Quantity")
                                .bold(true)
                            TextField(
                                "Quantity",
                                text: $VM.quantityString
                            )
                            .modifier(TextFieldModifier())
                        }
                case .maintenance:
                    
                    Picker("Equipment", selection: $VM.selectedEquipmentId) {
                        Text("Select Equipment").tag("")
                        ForEach(VM.equipmentList){ equipment in
                            Text("\(equipment.name) - \(equipment.category.rawValue)").tag(equipment.id)
                        }
                    }
                case .repair:
                    
                    Picker("Equipment", selection: $VM.selectedEquipmentId) {
                        Text("Select Equipment").tag("")
                        ForEach(VM.equipmentList){ equipment in
                            Text("\(equipment.name) - \(equipment.category.rawValue)").tag(equipment.id)
                        }
                    }
                }
            }
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany {
                        do {
                            try await VM.addNewTaskToJob(companyId: company.id, jobId: jobId, serviceLocationId: serviceLocationId)
                        } catch let error {
                            print(error)
                            let myError: AddNewTaskToJobError = error as! AddNewTaskToJobError
                            VM.alertMessage = myError.errorDescription
                            VM.showAlert.toggle()
                            
                        }
                    }
                }
            }, label: {
                HStack{
                    Spacer()
                    Text("Add New Task")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())
            })
        }
        .padding(8)
    }
}
