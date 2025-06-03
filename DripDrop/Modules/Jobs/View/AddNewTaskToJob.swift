//
//  AddNewTaskToJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//

import SwiftUI

struct AddNewTaskToJob: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    init(dataService:any ProductionDataServiceProtocol,jobId:String,taskTypes:[String],customerId:String,serviceLocationId:String){
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
extension AddNewTaskToJob {
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
                        Button(action: {
                            VM.showEquipmentPicker.toggle()
                        }, label: {
                            if VM.selectedEquipment.id != "" {
                                
                                Text("Select Equipment")
                            } else {
                                Text(VM.selectedEquipment.name)
                            }
                        })
                        .sheet(isPresented: $VM.showEquipmentPicker, content: {
                            EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: serviceLocationId, equipment: $VM.selectedEquipment)
                        })
                    
                    case .emptyWater:
                        Button(action: {
                            VM.showEquipmentPicker.toggle()
                        }, label: {
                            if VM.selectedBodyOfWater.id != "" {
                                
                                Text("Select Body Of Water")
                            } else {
                                Text(VM.selectedBodyOfWater.name)
                            }
                        })
                        .sheet(isPresented: $VM.showBOWPicker, content: {
                            BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                        })
                    case .fillWater:
                        Button(action: {
                            VM.showBOWPicker.toggle()
                        }, label: {
                            if VM.selectedBodyOfWater.id != "" {
                                
                                Text("Select Body Of Water")
                            } else {
                                Text(VM.selectedBodyOfWater.name)
                            }
                        })
                        .sheet(isPresented: $VM.showBOWPicker, content: {
                            BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                        })
                    case .inspection:
                        Text("Inspection")
                    case .install:
                        Button(action: {
                            VM.showBOWPicker.toggle()
                        }, label: {
                            if VM.selectedBodyOfWater.id != "" {
                                
                                Text("Select Body Of Water")
                            } else {
                                Text(VM.selectedBodyOfWater.name)
                            }
                        })
                        .sheet(isPresented: $VM.showBOWPicker, content: {
                            BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                        })
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
                        Button(action: {
                            VM.showEquipmentPicker.toggle()
                        }, label: {
                            if VM.selectedEquipment.id != "" {
                                
                                Text("Select Equipment")
                            } else {
                                Text(VM.selectedEquipment.name)
                            }
                        })
                        .sheet(isPresented: $VM.showEquipmentPicker, content: {
                            EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: serviceLocationId, equipment: $VM.selectedEquipment)
                        })
                    case .replace:
                        Button(action: {
                            VM.showEquipmentPicker.toggle()
                        }, label: {
                            if VM.selectedEquipment.id != "" {
                                
                                Text("Select Equipment")
                            } else {
                                Text(VM.selectedEquipment.name)
                            }
                        })
                        .sheet(isPresented: $VM.showEquipmentPicker, content: {
                            EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: serviceLocationId, equipment: $VM.selectedEquipment)
                        })
                        Button(action: {
                            VM.showEquipmentPicker.toggle()
                        }, label: {
                            if VM.selectedBodyOfWater.id != "" {
                                
                                Text("Select Body Of Water")
                            } else {
                                Text(VM.selectedBodyOfWater.name)
                            }
                        })
                        .sheet(isPresented: $VM.showBOWPicker, content: {
                            BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                        })
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
                    Button(action: {
                        VM.showEquipmentPicker.toggle()
                    }, label: {
                        if VM.selectedEquipment.id != "" {
                            
                            Text("Select Equipment")
                        } else {
                            Text(VM.selectedEquipment.name)
                        }
                    })
                    .sheet(isPresented: $VM.showEquipmentPicker, content: {
                        EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: serviceLocationId, equipment: $VM.selectedEquipment)
                    })
                case .repair:
                    Button(action: {
                        VM.showEquipmentPicker.toggle()
                    }, label: {
                        if VM.selectedBodyOfWater.id != "" {
                            
                            Text("Select Body Of Water")
                        } else {
                            Text(VM.selectedBodyOfWater.name)
                        }
                    })
                    .sheet(isPresented: $VM.showBOWPicker, content: {
                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                    })
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
