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
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack {
                HStack{
                    Spacer()
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.deleteTaskGroup(companyId: currentCompany.id, taskGroupId: taskGroup.id)
                        }
                    }, label: {
                        Text("Delete")
                            .modifier(DismissButtonModifier())
                    })
                }
                ScrollView {
                    form
                    Rectangle()
                        .frame(height: 1)
                    itemList
                }
                button
            }
            .padding(8)
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id, taskGroup: taskGroup)
            }
        }
        .onChange(of: VM.itemRate, perform: { rateStr in
            if rateStr != "" {
                if let rate = Double(rateStr) {
                    print(rate)
                } else {
                    VM.itemRate = String(rateStr.dropLast())
                }
            }
        })
        .onChange(of: VM.itemEstimatedTime, perform: { timeStr in
            if timeStr != "" {
                if let rate = Int(timeStr) {
                    print(rate)
                } else {
                    VM.itemEstimatedTime = String(timeStr.dropLast())
                }
            }
        })
    }
}

#Preview {
    AddNewTaskGroup(dataService: MockDataService())
}
extension TaskGroupDetailView {
    
    var form: some View {
        VStack{
            HStack{
                Text("Name : ")
                TextField(
                    "Name",
                    text: $VM.name
                )
                .modifier(TextFieldModifier())
            }
            HStack{
                Text("Description : ")
                TextField(
                    "Description",
                    text: $VM.description
                )
                .modifier(TextFieldModifier())
            }
        }
    }
    var itemList: some View {
        VStack{
            ForEach(VM.taskItemList){ item in
                VStack{
                    HStack{
                        Text(item.name)
                        Spacer()
                        Button(action: {
                            VM.taskItemList.removeAll(where: {$0.id == item.id})
                            if let currentCompany = masterDataManager.currentCompany {
                                VM.deleteTask(companyId: currentCompany.id, taskGroupId: taskGroup.id, taskId: item.id)
                            }
                        }, label: {
                            Text("Delete")
                                .modifier(DismissButtonModifier())
                        })
                    }
                    Text(item.description)
                        .font(.footnote)
                    HStack{
                        Text("Estimated Time: \(String(item.estimatedTime))")
                        Spacer()
                        Text("Contracted Rate : \(Double(item.contractedRate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    }
                    .font(.footnote)
                }
                .modifier(ListButtonModifier())
            }
            Divider()
            if VM.addNewItem {
                HStack{
                    Text("Name : ")
                    TextField(
                        "Name",
                        text: $VM.itemName
                    )
                    .modifier(TextFieldModifier())
                }
                Picker("Type", selection: $VM.itemType) {
                    ForEach(JobTaskType.allCases){ BOW in
                        Text(BOW.rawValue).tag(BOW)
                    }
                }
                HStack{
                    Text("Description : ")
                    TextField(
                        "Description",
                        text: $VM.itemDescription
                    )
                    .modifier(TextFieldModifier())
                }
                HStack{
                    Text("Item Rate : ")
                    TextField(
                        "Item Rate",
                        text: $VM.itemRate
                    )
                    .modifier(TextFieldModifier())
                }
                HStack{
                    Text("Estimated Time : ")
                    TextField(
                        "Estimated Time",
                        text: $VM.itemEstimatedTime
                    )
                    .modifier(TextFieldModifier())
                }
                HStack{
                    Button(action: {
                        VM.addNewItem.toggle()
                        
                        VM.itemEstimatedTime = ""
                        VM.itemRate = ""
                        VM.itemName = ""
                        VM.itemType = .basic
                        VM.itemDescription = ""
                        
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Clear")
                            Spacer()
                        }
                        .modifier(DismissButtonModifier())
                    })
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany {
                            if let time = Int(VM.itemEstimatedTime) {
                                if let rate = Int(VM.itemRate) {
                                    let item = JobTaskGroupItem(
                                        id: UUID().uuidString,
                                        name: VM.itemName,
                                        type: VM.itemType,
                                        description: VM.itemDescription,
                                        contractedRate: rate*100,
                                        estimatedTime: time
                                    )
                                    VM.uploadTaskItem(companyId: currentCompany.id, taskGroupId: taskGroup.id, task: item)
                                    VM.itemEstimatedTime = ""
                                    VM.itemRate = ""
                                    VM.itemName = ""
                                    VM.itemType = .basic
                                    VM.itemDescription = ""
                                    
                                }
                            }
                        }
                    },
                           label: {
                        HStack{
                            Spacer()
                            Text("Add To List")
                            Spacer()
                        }
                        .modifier(SubmitButtonModifier())
                    })
                }
            } else {
                Button(action: {
                    VM.addNewItem.toggle()
                }, label: {
                    HStack{
                        Spacer()
                        Text("Add New Item")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                })
            }
        }
    }
    var button: some View {
        HStack{
            Button(action: {
                
            }, label: {
                HStack{
                    Spacer()
                    Text("Discard")
                    Spacer()
                }
                .modifier(DismissButtonModifier())
            })
            Button(action: {
                
            }, label: {
                HStack{
                    Spacer()
                    Text("Save")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())
            })
        }
    }
}

