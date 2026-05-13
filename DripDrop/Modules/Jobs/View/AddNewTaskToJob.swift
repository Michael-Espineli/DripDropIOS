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
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {

                    // Header card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add Task")
                                .font(.title3.weight(.semibold))
                            Text("Job: \(jobId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .ddCard()

                    // Main form
                    formView
                        .ddCard()

                    // Spacer so bottom bar doesn’t cover content
                    Color.clear.frame(height: 80)
                }
                .padding(12)
            }

            VStack {
                Spacer()
                addButtonBar
            }
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
    
    var formView: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Task Details")
                .font(.headline.weight(.semibold))

            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    DDLabel(text: "Name")
                    TextField("Name", text: $VM.name)
                        .modifier(TextFieldModifier())
                }

                HStack(alignment: .center, spacing: 10) {
                    DDLabel(text: "Contracted Rate")
                    TextField("Contracted Rate", text: $VM.contractedRateString)
                        .modifier(TextFieldModifier())
                }

                HStack(alignment: .center, spacing: 10) {
                    DDLabel(text: "Estimated Time")
                    TextField("Estimated Time", text: $VM.estimatedTimeString)
                        .modifier(TextFieldModifier())
                }
            }

            Divider().opacity(0.15)

            Text("Task Type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Button(action: {
                VM.showTaskTypePicker.toggle()
            }, label: {
                HStack {
                    Text(VM.selectedTaskType.rawValue)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
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
            })
            .sheet(isPresented: $VM.showTaskTypePicker) {
                JobTaskTypePicker(taskType: $VM.selectedTaskType)
            }

            Divider().opacity(0.15)

            extraDetailsSection
        }
    }
    
    var extraDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Extra Details")
                .font(.headline.weight(.semibold))

            switch VM.selectedTaskType {
            case .basic, .clean:
                Text("No extra details needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .cleanFilter, .remove, .maintenance:
                Button(action: { VM.showEquipmentPicker.toggle() }, label: {
                    pickerRow(
                        title: "Equipment",
                        value: VM.selectedEquipment.id == "" ? "Select Equipment" : VM.selectedEquipment.name
                    )
                })
                .sheet(isPresented: $VM.showEquipmentPicker) {
                    EquipmentPickerByServiceLocationId(
                        dataService: dataService,
                        serviceLocationId: serviceLocationId,
                        equipment: $VM.selectedEquipment
                    )
                }

            case .emptyWater, .fillWater, .install, .replace, .repair:
                // Body of Water picker
                Button(action: { VM.showBOWPicker.toggle() }, label: {
                    pickerRow(
                        title: "Body Of Water",
                        value: VM.selectedBodyOfWater.id == "" ? "Select Body Of Water" : VM.selectedBodyOfWater.name
                    )
                })
                .sheet(isPresented: $VM.showBOWPicker) {
                    BodyOfWaterPicker(
                        dataService: dataService,
                        serviceLocationId: serviceLocationId,
                        bodyOfWater: $VM.selectedBodyOfWater
                    )
                }

                // Equipment picker only needed in replace (you had it)
                if VM.selectedTaskType == .replace {
                    Button(action: { VM.showEquipmentPicker.toggle() }, label: {
                        pickerRow(
                            title: "Equipment",
                            value: VM.selectedEquipment.id == "" ? "Select Equipment" : VM.selectedEquipment.name
                        )
                    })
                    .sheet(isPresented: $VM.showEquipmentPicker) {
                        EquipmentPickerByServiceLocationId(
                            dataService: dataService,
                            serviceLocationId: serviceLocationId,
                            equipment: $VM.selectedEquipment
                        )
                    }
                }

                // Item picker needed for install / replace
                if VM.selectedTaskType == .install || VM.selectedTaskType == .replace {
                    Button(action: { VM.showItemPicker.toggle() }, label: {
                        pickerRow(
                            title: "Item",
                            value: VM.dataBaseItem.id == "" ? "Select Item" : VM.dataBaseItem.name
                        )
                    })
                    .sheet(isPresented: $VM.showItemPicker) {
                        DataBaseItemPicker(dataService: dataService, DBItem: $VM.dataBaseItem, category: .equipment)
                    }

                    HStack(alignment: .center, spacing: 10) {
                        DDLabel(text: "Quantity")
                        TextField("Quantity", text: $VM.quantityString)
                            .modifier(TextFieldModifier())
                    }
                }

            case .inspection:
                Text("Inspection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func pickerRow(title: String, value: String) -> some View {
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
    
    var addButtonBar: some View {
        HStack {
            Button(action: {
                Task {
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
                Text("Add New Task")
                    .frame(maxWidth: .infinity)
                    .modifier(SubmitButtonModifier())
            })
        }
        .ddBottomBar()
    }

}
private extension View {
    func ddCard() -> some View {
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

    func ddBottomBar() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color.black.opacity(0.02)
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .overlay(Divider().opacity(0.12), alignment: .top)
    }
}

private struct DDLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 130, alignment: .leading)   // keeps rows aligned
    }
}
