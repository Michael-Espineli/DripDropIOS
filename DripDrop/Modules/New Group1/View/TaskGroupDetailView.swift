//
//  TaskGroupDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import SwiftUI
@MainActor
final class TaskGroupDetailViewViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showNewTaskGroup : Bool = false

    @Published var name : String = ""
    @Published var description : String = ""
    @Published var previousTaskItemList : [JobTaskGroupItem] = []
    @Published private(set) var typeList : [String] = []

    @Published var taskItemList : [JobTaskGroupItem] = []
    @Published var addNewItem : Bool = false
    
    @Published var itemName : String = ""
    @Published var itemType : JobTaskType = .basic
    @Published var itemDescription : String = ""
    @Published var itemRate : String = ""
    @Published var itemEstimatedTime : String = ""
    
    func onLoad(companyId:String,taskGroup:JobTaskGroup){
        Task{
            do {
                self.name = taskGroup.name
                self.description = taskGroup.description
                self.typeList = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]

                self.taskItemList = try await dataService.getAllTaskGroupItems(companyId: companyId, taskGroupId: taskGroup.id)
            } catch {
                print(error)
            }
        }
    }
    func uploadTaskItem(companyId:String,taskGroupId:String,task:JobTaskGroupItem) {
        Task{
            do {
                try await dataService.uploadNewTaskGroupItem(companyId: companyId, taskGroupId: taskGroupId, taskGroupItem: task)
            } catch {
                print(error)
            }
        }
    }
    func deleteTaskGroup(companyId:String,taskGroupId:String) {
        Task{
            do {
                try await dataService.deleteTaskGroup(companyId: companyId, taskGroupId: taskGroupId)
            } catch {
                print(error)
            }
        }
    }
    func deleteTask(companyId:String,taskGroupId:String,taskId:String) {
        Task{
            do {
                try await dataService.deleteTaskGroupItem(companyId: companyId, taskGroupId: taskGroupId, taskId: taskId)
            } catch {
                print(error)
            }
        }
    }
}
struct TaskGroupDetailView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : TaskGroupDetailViewViewModel
    @State var taskGroup : JobTaskGroup

    init(dataService : any ProductionDataServiceProtocol, taskGroup : JobTaskGroup){
        _VM = StateObject(wrappedValue: TaskGroupDetailViewViewModel(dataService: dataService))
        _taskGroup = State(wrappedValue: taskGroup)
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 16) {

                // MARK: Header
                HStack {
                    Text("Task Group Details")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Button("Delete") {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.deleteTaskGroup(
                                companyId: currentCompany.id,
                                taskGroupId: taskGroup.id
                            )
                        }
                    }
                    .modifier(DismissButtonModifier())
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
                VM.onLoad(companyId: currentCompany.id, taskGroup: taskGroup)
            }
        }
        .onChange(of: VM.itemRate) { rateStr in
            if rateStr != "", Double(rateStr) == nil {
                VM.itemRate = String(rateStr.dropLast())
            }
        }
        .onChange(of: VM.itemEstimatedTime) { timeStr in
            if timeStr != "", Int(timeStr) == nil {
                VM.itemEstimatedTime = String(timeStr.dropLast())
            }
        }
    }
}

#Preview {
    AddNewTaskGroup(dataService: MockDataService())
}
// ✅ FORM SECTION (Card Style)
extension TaskGroupDetailView {

    var form: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Details")
                .font(.headline)

            VStack(spacing: 12) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Name", text: $VM.name)
                        .modifier(TextFieldModifier())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Description", text: $VM.description)
                        .modifier(TextFieldModifier())
                }
            }
            .padding(14)
            .background(Color.darkGray.opacity(0.35))
            .cornerRadius(14)
        }
    }
}
//✅ ITEM LIST SECTION (Modern Card Layout)
extension TaskGroupDetailView {

    var itemList: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Tasks")
                .font(.headline)

            VStack(spacing: 12) {

                ForEach(VM.taskItemList) { item in
                    VStack(alignment: .leading, spacing: 8) {

                        HStack {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Button("Delete") {
                                VM.taskItemList.removeAll(where: {$0.id == item.id})
                                if let currentCompany = masterDataManager.currentCompany {
                                    VM.deleteTask(
                                        companyId: currentCompany.id,
                                        taskGroupId: taskGroup.id,
                                        taskId: item.id
                                    )
                                }
                            }
                            .modifier(DismissButtonModifier())
                        }

                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }

                        HStack {
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
//✅ NEW ITEM ENTRY (Cleaner + Structured)
extension TaskGroupDetailView {

    var newItemSection: some View {
        VStack(spacing: 12) {

            if VM.addNewItem {

                VStack(alignment: .leading, spacing: 12) {

                    Text("New Task")
                        .font(.subheadline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Task Name", text: $VM.itemName)
                            .modifier(TextFieldModifier())
                    }

                    Picker("Type", selection: $VM.itemType) {
                        ForEach(JobTaskType.allCases) {
                            Text($0.rawValue).tag($0)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Description", text: $VM.itemDescription)
                            .modifier(TextFieldModifier())
                    }

                    HStack(spacing: 12) {

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("0", text: $VM.itemRate)
                                .modifier(TextFieldModifier())
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated Time")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Min", text: $VM.itemEstimatedTime)
                                .modifier(TextFieldModifier())
                        }
                    }

                    HStack(spacing: 12) {

                        Button("Clear") {
                            VM.addNewItem.toggle()
                            VM.itemEstimatedTime = ""
                            VM.itemRate = ""
                            VM.itemName = ""
                            VM.itemType = .basic
                            VM.itemDescription = ""
                        }
                        .modifier(DismissButtonModifier())

                        Button("Add To List") {
                            if let currentCompany = masterDataManager.currentCompany,
                               let time = Int(VM.itemEstimatedTime),
                               let rate = Int(VM.itemRate) {

                                let item = JobTaskGroupItem(
                                    id: UUID().uuidString,
                                    name: VM.itemName,
                                    type: VM.itemType,
                                    description: VM.itemDescription,
                                    contractedRate: rate*100,
                                    estimatedTime: time
                                )

                                VM.uploadTaskItem(
                                    companyId: currentCompany.id,
                                    taskGroupId: taskGroup.id,
                                    task: item
                                )

                                VM.itemEstimatedTime = ""
                                VM.itemRate = ""
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
//✅ Bottom Buttons (Balanced + Cleaner)
extension TaskGroupDetailView {

    var button: some View {
        HStack(spacing: 12) {

            Button("Discard") {

            }
            .modifier(DismissButtonModifier())

            Button("Save") {

            }
            .modifier(SubmitButtonModifier())
        }
    }
}

