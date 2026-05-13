//
//  AddNewTaskGroup.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import SwiftUI
@MainActor
final class AddNewTaskGroupViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showNewTaskGroup : Bool = false
    @Published private(set) var typeList : [String] = []

    @Published var name : String = ""
    @Published var description : String = ""
    
    @Published var taskItemList : [JobTaskGroupItem] = []
    @Published var addNewItem : Bool = false
    
    @Published var itemName : String = ""
    @Published var itemType : JobTaskType = .basic
    @Published var itemDescription : String = ""
    @Published var itemRate : String = "0"
    @Published var itemEstimatedTime : String = "0"
    
    func onLoad(companyId:String){
        Task{
            self.typeList = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]
        }
    }
    func submitNewTaskGroup(companyId:String){
        Task{
            do {
                let taskGroupId = UUID().uuidString
                let taskGroup = JobTaskGroup(
                    id: taskGroupId,
                    name: name,
                    description: description,
                    numberOfTasks: taskItemList.count
                )
                try await dataService.uploadNewTaskGroup(companyId: companyId, taskGroup: taskGroup)
                for item in taskItemList {
                    try await dataService.uploadNewTaskGroupItem(companyId: companyId, taskGroupId: taskGroupId, taskGroupItem: item)
                }
                print("Successfully Uploaded Task")
                print(taskGroup)
                print(taskItemList)
                self.name = ""
                self.description = ""
                self.taskItemList = []
            } catch {
                print(error)
            }
        }
    }
}

struct AddNewTaskGroup: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject var VM : AddNewTaskGroupViewModel

    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AddNewTaskGroupViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 16) {

                // MARK: Header
                HStack {
                    Text("New Task Group")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonModifier())
                    }
                }
                .padding(.horizontal)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        form
                        itemList
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                button
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id)
            }
        }
        .onChange(of: VM.itemRate) { rateStr in
            if rateStr != "" {
                if Double(rateStr) == nil {
                    VM.itemRate = String(rateStr.dropLast())
                }
            }
        }
        .onChange(of: VM.itemEstimatedTime) { timeStr in
            if timeStr != "" {
                if Int(timeStr) == nil {
                    VM.itemEstimatedTime = String(timeStr.dropLast())
                }
            }
        }
    }
}


#Preview {
    AddNewTaskGroup(dataService: MockDataService())
}
// ✅ FORM SECTION (Card Based)
extension AddNewTaskGroup {
    
    var form: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Details")
                .font(.headline)

            VStack(spacing: 12) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Task Group Name", text: $VM.name)
                        .modifier(PlainTextFieldModifier())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Description", text: $VM.description)
                        .modifier(PlainTextFieldModifier())
                }
            }
            .padding(14)
            .background(Color.darkGray.opacity(0.35))
            .cornerRadius(14)
        }
    }
}
// ✅ ITEM LIST SECTION (Cleaner Card List)
extension AddNewTaskGroup {

    var itemList: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Tasks")
                .font(.headline)

            VStack(spacing: 12) {

                ForEach(VM.taskItemList) { item in
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }

                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Label("\(item.estimatedTime) min", systemImage: "clock")
                            Spacer()
                            Text(
                                Double(item.contractedRate)/100,
                                format: .currency(code: "USD")
                            )
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.darkGray.opacity(0.35))
                    .cornerRadius(14)
                }

                newItemSection
            }
        }
    }
}
//  ✅ NEW ITEM ENTRY (Much Cleaner Layout)
extension AddNewTaskGroup {

    var newItemSection: some View {
        VStack(spacing: 12) {

            if VM.addNewItem {

                VStack(alignment: .leading, spacing: 12) {

                    Text("New Task")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Task Name", text: $VM.itemName)
                            .modifier(PlainTextFieldModifier())
                    }

                    Picker("Type", selection: $VM.itemType) {
                        ForEach(JobTaskType.allCases, id:\.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Description", text: $VM.itemDescription)
                            .modifier(PlainTextFieldModifier())
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("$")
                                TextField("0", text: $VM.itemRate)
                            }
                            .modifier(PlainTextFieldModifier())
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Est. Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Min", text: $VM.itemEstimatedTime)
                                .modifier(PlainTextFieldModifier())
                        }
                    }

                    HStack(spacing: 12) {
                        Button("Clear") {
                            VM.addNewItem.toggle()
                            VM.itemEstimatedTime = "0"
                            VM.itemRate = "0"
                            VM.itemName = ""
                            VM.itemType = .basic
                            VM.itemDescription = ""
                        }
                        .modifier(DismissButtonModifier())

                        Button("Add To List") {
                            if let time = Int(VM.itemEstimatedTime),
                               let rate = Int(VM.itemRate) {

                                let item = JobTaskGroupItem(
                                    id: UUID().uuidString,
                                    name: VM.itemName,
                                    type: VM.itemType,
                                    description: VM.itemDescription,
                                    contractedRate: rate*100,
                                    estimatedTime: time
                                )

                                VM.taskItemList.append(item)

                                VM.itemEstimatedTime = "0"
                                VM.itemRate = "0"
                                VM.itemName = ""
                                VM.itemType = .basic
                                VM.itemDescription = ""
                            }
                        }
                        .modifier(SubmitButtonModifier())
                    }
                }
                .padding(14)
                .background(Color.darkGray.opacity(0.35))
                .cornerRadius(14)

            } else {

                Button {
                    VM.addNewItem.toggle()
                } label: {
                    HStack {
                        Spacer()
                        Text("Add New Item")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                }
            }
        }
    }
}
//  ✅ Submit Button (Cleaner)
extension AddNewTaskGroup {

    var button: some View {
        Button {
            if let currentCompany = masterDataManager.currentCompany {
                VM.submitNewTaskGroup(companyId: currentCompany.id)
            }
        } label: {
            HStack {
                Spacer()
                Text("Submit")
                Spacer()
            }
            .modifier(SubmitButtonModifier())
        }
    }
}
