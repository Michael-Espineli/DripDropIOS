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
            do {
                self.typeList = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]
            } catch {
                print(error)
            }
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
    

    @StateObject var VM : AddNewTaskGroupViewModel
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AddNewTaskGroupViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack {
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
                VM.onLoad(companyId: currentCompany.id)
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
extension AddNewTaskGroup {
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
                    }
                    Text(item.description)
                        .font(.footnote)
                    HStack{
                        Text("Estimated Time: \(String(item.estimatedTime))")
                        Text("\(Double(item.contractedRate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
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
                
                HStack{
                    Text("Type : ")
                    Picker("Type", selection: $VM.itemType) {
                        ForEach(VM.typeList, id:\.self){ datum in
                            Text(datum).tag(datum)
                        }
                    }
                    Spacer()
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
                    Text("Contract Rate : ")
                    HStack{
                        Text("$")
                        TextField(
                            "Item Rate",
                            text: $VM.itemRate
                        )
                    }
                    .modifier(TextFieldModifier())
                }
                HStack{
                    Text("Estimated Time : ")
                    TextField(
                        "Min",
                        text: $VM.itemEstimatedTime
                    )
                    .modifier(TextFieldModifier())
                }
                HStack{
                    Button(action: {
                        VM.addNewItem.toggle()
                        
                        VM.itemEstimatedTime = "0"
                        VM.itemRate = "0"
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
                                VM.taskItemList.append(item)
                                
                                VM.itemEstimatedTime = "0"
                                VM.itemRate = "0"
                                VM.itemName = ""
                                VM.itemType = .basic
                                VM.itemDescription = ""
                                
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
        VStack{
            Button(action: {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.submitNewTaskGroup(companyId: currentCompany.id)
                }
            }, label: {
                HStack{
                    Spacer()
                    Text("Submit")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())

            })
        }
    }
}
