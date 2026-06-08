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

    init(dataService:any ProductionDataServiceProtocol,jobId:String,taskTypes:[String],customerId:String,serviceLocationId:String, tasks:Binding<[JobTask]>, shoppingList:Binding<[ShoppingListItem]>){
        _VM = StateObject(wrappedValue: AddNewTaskToJobViewModel(dataService: dataService))

        _jobId = State(wrappedValue: jobId)
        _taskTypes = State(wrappedValue: taskTypes)
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        self._tasks = tasks
        self._shoppingList = shoppingList
    }
    
    @StateObject var VM : AddNewTaskToJobViewModel
    @State var jobId:String
    @State var taskTypes:[String]
    @State var customerId:String
    @State var serviceLocationId:String
    @Binding var tasks:[JobTask]
    @Binding var shoppingList:[ShoppingListItem]

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
    var formView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Task")
                        .font(.title3.weight(.semibold))
                    Text("Build the task with the records it needs before this job is saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .draftTaskCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Task Details")
                        .font(.headline.weight(.semibold))

                    draftTaskField(title: "Name", placeholder: "Name", text: $VM.name)
                    draftTaskField(title: "Contracted Rate", placeholder: "Contracted Rate", text: $VM.contractedRateString)
                    draftTaskField(title: "Estimated Time", placeholder: "Estimated Time", text: $VM.estimatedTimeString)

                    Divider().opacity(0.15)

                    Text("Task Type")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Button(action: { VM.showTaskTypePicker.toggle() }, label: {
                        draftPickerRow(title: "Type", value: VM.selectedTaskType.rawValue)
                    })
                    .sheet(isPresented: $VM.showTaskTypePicker, content: {
                        JobTaskTypePicker(taskType: $VM.selectedTaskType)
                            .presentationDetents([.large, .medium])
                    })

                    Divider().opacity(0.15)

                    extraDetailsSection
                }
                .draftTaskCard()

                addTaskButton
            }
            .padding(12)
        }
    }

    var extraDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extra Details")
                .font(.headline.weight(.semibold))

            switch VM.selectedTaskType {
            case .basic, .clean, .inspection:
                Text("No extra details needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .cleanFilter, .remove, .maintenance, .repair:
                Button(action: { VM.showEquipmentPicker.toggle() }, label: {
                    draftPickerRow(
                        title: "Equipment",
                        value: VM.selectedEquipment.id.isEmpty ? "Select Equipment" : VM.selectedEquipment.name
                    )
                })
                .sheet(isPresented: $VM.showEquipmentPicker, content: {
                    EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: serviceLocationId, equipment: $VM.selectedEquipment)
                })

            case .emptyWater, .fillWater, .install, .replace:
                Button(action: { VM.showBOWPicker.toggle() }, label: {
                    draftPickerRow(
                        title: "Body Of Water",
                        value: VM.selectedBodyOfWater.id.isEmpty ? "Select Body Of Water" : VM.selectedBodyOfWater.name
                    )
                })
                .sheet(isPresented: $VM.showBOWPicker, content: {
                    BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                })

                if VM.selectedTaskType == .replace {
                    Button(action: { VM.showEquipmentPicker.toggle() }, label: {
                        draftPickerRow(
                            title: "Equipment",
                            value: VM.selectedEquipment.id.isEmpty ? "Select Equipment" : VM.selectedEquipment.name
                        )
                    })
                    .sheet(isPresented: $VM.showEquipmentPicker, content: {
                        EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: serviceLocationId, equipment: $VM.selectedEquipment)
                    })
                }

                if VM.selectedTaskType == .install || VM.selectedTaskType == .replace {
                    Button(action: { VM.showItemPicker.toggle() }, label: {
                        draftPickerRow(
                            title: "Item",
                            value: VM.dataBaseItem.id.isEmpty ? "Select Item" : VM.dataBaseItem.name
                        )
                    })
                    .sheet(isPresented: $VM.showItemPicker, content: {
                        DataBaseItemPicker(dataService: dataService, DBItem: $VM.dataBaseItem, category: .equipment)
                    })

                    draftTaskField(title: "Quantity", placeholder: "Quantity", text: $VM.quantityString)
                }
            }
        }
    }

    var addTaskButton: some View {
        Button(action: {
            Task {
                if let company = masterDataManager.currentCompany {
                    do {
                        let values = try await VM.addNewTaskToJobTaskList(companyId: company.id, jobId: jobId, serviceLocationId: serviceLocationId)
                        tasks.append(values.0)
                        if let item = values.1 {
                            shoppingList.append(item)
                        }
                    } catch let error {
                        print(error)
                        let myError: AddNewTaskToJobError = error as! AddNewTaskToJobError
                        VM.alertMessage = myError.errorDescription
                        VM.showAlert.toggle()
                    }
                }
            }
        }, label: {
            HStack {
                Spacer()
                Text("Add New Task")
                Spacer()
            }
            .modifier(SubmitButtonModifier())
        })
    }

    func draftTaskField(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            TextField(placeholder, text: text)
                .modifier(TextFieldModifier())
        }
    }

    func draftPickerRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(value.hasPrefix("Select") ? .secondary : .primary)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

private extension View {
    func draftTaskCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}
