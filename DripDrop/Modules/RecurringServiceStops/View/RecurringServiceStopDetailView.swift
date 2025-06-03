//
//  RecurringServiceStopDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import SwiftUI
@MainActor
final class RecurringServiceStopDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var taskItems: [JobTaskGroupItem] = []
    @Published private(set) var RSSTasks: [RecurringServiceStopTask] = []
    @Published var showAddTask : Bool = false
    @Published var isLoading : Bool = false

    @Published var showAddTaskGroup : Bool = false
    @Published var showCreateNewTaskGroup : Bool = false

    func onLoad(companyId:String,recurringServiceStop:RecurringServiceStop) {
        Task{
            do {
                self.RSSTasks = try await dataService.getRecurringServiceStopTasks(companyId: companyId, recurringServiceStopId: recurringServiceStop.id)

            } catch {
                print(error)
            }
        }
    }
    func updateRSS(companyId:String){
        Task{
            do {
                //DELETE THIS WAS A ONE TIME FUNCTION TO UPDATE THE OLD RSS'S TO HAVE TASKS
//                self.isLoading = true
//                let taskGroupItems = try await dataService.getAllTaskGroupItems(companyId: companyId, taskGroupId: "F55866BB-68E2-4522-BE29-E136385CB861")
//                let RSSList = try await dataService.getAllRecurringServiceStop(companyId: companyId)
//                print("Received \(RSSList.count) RSS")
//                var count = 0
//                
//                for rss in RSSList {
//                    count += 1
//                    print("\(count) - \(rss.id)")
//                    for task in taskGroupItems {
//                        let ssTask = RecurringServiceStopTask(
//                            name: task.name,
//                            type: task.type,
//                            description: task.description,
//                            contractedRate: task.contractedRate,
//                            estimatedTime: task.estimatedTime
//                        )
//                        try await dataService.uploadRecurringServiceStopTask(companyId: companyId, recurringServiceStopId: rss.id, task: ssTask)
//                    }
//                }
//                print("Successfull")
//                self.isLoading = false
            } catch {
                print("error updateRSS")
                print(error)
            }
        }
    }
    func addNewTasks(companyId:String,recurringServiceStopId:String) {
        Task{
            do {
                for task in taskItems {
                    let recurringTask = RecurringServiceStopTask(
                        name: task.name,
                        type: task.type,
                        contractedRate: task.contractedRate,
                        estimatedTime: task.estimatedTime,
                        status: .unassigned
                    )
                    RSSTasks.append(recurringTask)
                    try await dataService.uploadRecurringServiceStopTask(companyId: companyId, recurringServiceStopId: recurringServiceStopId, task: recurringTask)
                }
                self.taskItems = []
            } catch {
                print(error)
            }
        }
    }
    func deleteTask(companyId:String,recurringServiceStopId:String,taskId:String) {
        Task{
            do {
                try await dataService.deleteRecurringServiceStopTask(companyId: companyId, recurringServiceStopId: recurringServiceStopId, taskId: taskId)
            } catch {
                print(error)
            }
        }
    }
}
struct RecurringServiceStopDetailView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : RecurringServiceStopDetailViewModel
    
    @State var RSS : RecurringServiceStop
    init(dataService : any ProductionDataServiceProtocol, RSS : RecurringServiceStop) {
        _RSS = State(wrappedValue: RSS)
        _VM = StateObject(wrappedValue: RecurringServiceStopDetailViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.updateRSS(companyId: currentCompany.id)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Edit")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    })
                    Button(action: {
                        
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Delete")
                            Spacer()
                        }
                        .modifier(DismissButtonModifier())
                    })
                }
            ScrollView{
                details
                if RSS.otherCompany {
                    otherCompanyDetails
                }
                taskItems
            }
        }
            .padding(8)
    }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id, recurringServiceStop: RSS)
            }
        }
    }
}
//
//#Preview {
//    RecurringServiceStopDetailView()
//}
extension RecurringServiceStopDetailView {
    var details: some View {
        VStack{
            HStack{
                Text("")
                Text(RSS.customerName)
                Spacer()
            }
            HStack{
                Text("")
                Text(RSS.address.streetAddress)
                Spacer()
            }
            HStack{
                Text("")
                Text(RSS.tech)
                Spacer()
            }
            HStack{
                Text("")
                
                Text(fullDate(date: RSS.dateCreated))
                Spacer()
            }
            HStack{
                Text("")
                
                Text(fullDate(date: RSS.startDate))
                Spacer()
            }
            HStack{
                Text("")
                Text(RSS.frequency.rawValue)
                Spacer()
            }
            HStack{
                Text("")
                Text(RSS.daysOfWeek)
                Spacer()
            }
            HStack{
                Text("")
                Text(fullDate(date: RSS.lastCreated))
                Spacer()
            }
            HStack{
                Text("")
                Text(RSS.estimatedTime)
                
                Spacer()
            }
            HStack{
                Text("")
                Text(RSS.description)
                
                Spacer()
            }
        }
    }
    
    var otherCompanyDetails: some View {
            VStack{
                if let laborContractId = RSS.laborContractId {
                    HStack{
                        Text("laborContractId")
                        Text(laborContractId)
                        
                        Spacer()
                    }
                }
                if let contractedCompanyId = RSS.contractedCompanyId {
                    HStack{
                        Text("contractedCompanyId")
                        Text(contractedCompanyId)
                        
                        Spacer()
                    }
                }
            }
        
    }
    var taskItems: some View {
        VStack{
            HStack{
                Button(action: {
                    VM.showAddTask.toggle()
                }, label: {
                    HStack{
                        Spacer()
                        Text("Add Task")
                        Spacer()
                    }
                    .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $VM.showAddTask, onDismiss: {
                    
                }, content: {
                    Text("Add Task")
                })
                Button(action: {
                    VM.showAddTaskGroup.toggle()
                }, label: {
                    HStack{
                        Spacer()
                        Text("Add Group")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                })
                .disabled(!VM.taskItems.isEmpty)
                .sheet(isPresented: $VM.showAddTaskGroup, onDismiss: {
                    if let currentCompany = masterDataManager.currentCompany {
                        VM.addNewTasks(companyId: currentCompany.id, recurringServiceStopId: RSS.id)
                    }
                }, content: {
                    TaskGroupPickerView(dataService: dataService, tasks: $VM.taskItems)

                })
            }
            Button(action: {
                VM.showAddTaskGroup.toggle()
            }, label: {
                HStack{
                    Spacer()
                    Text("Create New Task Group")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())
            })
            .sheet(isPresented: $VM.showCreateNewTaskGroup, onDismiss: {
                
            }, content: {
                Text("Create New Task Group")
            })
            Text("Task Items")

            ForEach(VM.RSSTasks){ task in
                VStack{
                    HStack{
                        Spacer()
                        Text(task.name)
                        Spacer()
                    }
                }
                .modifier(ListButtonModifier())
            }
            if !VM.taskItems.isEmpty {
                HStack{
                    Text("Loading...")
                    ProgressView()
                }
            }
        }
    }
}
