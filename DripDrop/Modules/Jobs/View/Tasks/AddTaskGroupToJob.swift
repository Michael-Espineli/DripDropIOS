    //
    //  AddTaskGroupToJob.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/4/24.
    //

import SwiftUI

@MainActor
final class AddTaskGroupToJobViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var searchTerm : String = ""
    @Published private(set) var dataTaskGroups : [JobTaskGroup] = []
    @Published var taskGroups : [JobTaskGroup] = []
    @Published var selectedTaskGroup : JobTaskGroup? = nil
    
    @Published private(set) var jobTasks : [JobTaskGroupItem] = []
    @Published var selectedJobTasks : [JobTaskGroupItem] = []

    func onLoad(commpanyId:String) async throws {
        self.dataTaskGroups = [
            JobTaskGroup(
                id: UUID().uuidString,
                name: "Filter Cleaning",
                description: "The Tasks involded in cleaning a filter from start to finish",
                numberOfTasks: 5
            )
        ]
        self.taskGroups = dataTaskGroups
    }
    func changeOfSelectedTaskGroup(commpanyId:String) async throws {
        //Developer Fix
        if let selectedTaskGroup {
            self.jobTasks = [
                JobTaskGroupItem(
                    id: UUID().uuidString,
                    name: "Spray Down Grids",
                    type: .cleanFilter,
                    description: "",
                    contractedRate: 2500,
                    estimatedTime: 1000
                ),
                JobTaskGroupItem(
                    id: UUID().uuidString,
                    name: "Replace Filter Medium",
                    type: .cleanFilter,
                    description: "",
                    contractedRate: 1500,
                    estimatedTime: 1200
                ),
                JobTaskGroupItem(
                    id: UUID().uuidString,
                    name: "Check For broken Parts",
                    type: .cleanFilter,
                    description: "",
                    contractedRate: 2000,
                    estimatedTime: 1100
                )
            ]
            
        } else {
            self.jobTasks = []
        }
    }
    func addTasksToJob(companyId:String,jobId:String) async throws {
        for task in selectedJobTasks {
            let jobTask = JobTask(
                name: task.name,
                type: task.type,
                contractedRate: task.contractedRate,
                estimatedTime: task.estimatedTime,
                status: .draft,
                customerApproval: true,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(
                    id: "",
                    internalId: ""
                ),
                equipmentId: "",
                serviceLocationId: "",
                bodyOfWaterId: "",
                dataBaseItemId: ""
            )
            try await dataService.uploadJobTask(companyId: companyId, jobId: jobId, task: jobTask)
            self.selectedTaskGroup = nil
            self.jobTasks = []
            self.selectedJobTasks = []

        }
    }
}
struct AddTaskGroupToJob: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : AddTaskGroupToJobViewModel
    @State var jobId:String
    @State var taskTypes:[String]
    @State var customerId:String
    @State var serviceLocationId:String
    init(dataService:any ProductionDataServiceProtocol,jobId:String,taskTypes:[String],customerId:String,serviceLocationId:String){
        _VM = StateObject(wrappedValue: AddTaskGroupToJobViewModel(dataService: dataService))
        
        _jobId = State(wrappedValue: jobId)
        _taskTypes = State(wrappedValue: taskTypes)
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if let selectedTaskGroup = VM.selectedTaskGroup {
                    taskGroupDetails
                } else {
                    searchBar
                    taskGroupList
                }
            }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(commpanyId: currentCompany.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: VM.selectedTaskGroup, perform: { group in
            Task{
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.changeOfSelectedTaskGroup(commpanyId : currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
                
            }
        })
    }
}
extension AddTaskGroupToJob {
    var searchBar: some View {
        HStack{
            TextField(
                "Search Term",
                text: $VM.searchTerm,
                axis: .vertical
            )
            Button(action: {
                VM.searchTerm = ""
            }, label: {
                Image(systemName: "xmark")
            })
        }
        .modifier(SearchTextFieldModifier())
        .padding(8)
    }
    var taskGroupList: some View {
        ScrollView{
            ForEach(VM.taskGroups) { group in
                Button(action: {
                    VM.selectedTaskGroup = group
                }, label: {
                    VStack{
                        HStack{
                            Spacer()
                            Text(group.name)
                            Spacer()
                        }
                        Text(group.description)
                            .lineLimit(2,reservesSpace: true)
                            .font(.footnote)
                        
                    }
                    .modifier(ListButtonModifier())
                })
                .padding(4)
            }
        }
    }
    var taskGroupDetails: some View {
        VStack{
            if let selectedTaskGroup = VM.selectedTaskGroup {
                HStack{
                    Button(action: {
                        VM.selectedTaskGroup = nil
                    }, label: {
                        Text("Back")
                    })
                    Spacer()
                    Button(action: {
                        Task{
                            if let currentCompany = masterDataManager.currentCompany {
                                do {
                                    try await VM.addTasksToJob(companyId: currentCompany.id, jobId: jobId)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, label: {
                        Text("Add")
                    })
                }
                ScrollView{
                    Text(selectedTaskGroup.name)
                        .font(.headline)
                    Text(selectedTaskGroup.description)
                    Text(String(VM.jobTasks.count))
                    Rectangle()
                        .frame(height: 1)
                    HStack{
                        Button(action: {
                            if VM.jobTasks == VM.selectedJobTasks {
                                VM.selectedJobTasks = []
                            } else {
                                VM.selectedJobTasks = VM.jobTasks
                            }
                        }, label: {
                            ZStack{
                                Image(systemName: VM.jobTasks == VM.selectedJobTasks ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor( VM.jobTasks == VM.selectedJobTasks ? Color.poolGreen : Color.black)
                                    .font(.headline)

                            }
                            .padding(4)
                        })
                        Spacer()
                    }
                    ForEach(VM.jobTasks) { task in
                        HStack{
                            Button(action: {
                                if VM.selectedJobTasks.contains(where: {$0.id == task.id}) {
                                    VM.selectedJobTasks.removeAll(where: {$0.id == task.id})
                                } else {
                                    VM.selectedJobTasks.append(task)
                                }
                            }, label: {
                                ZStack{
                                    Image(systemName: VM.selectedJobTasks.contains(where: {$0.id == task.id}) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(VM.selectedJobTasks.contains(where: {$0.id == task.id}) ? Color.poolGreen : Color.black)
                                        .font(.headline)

                                }
                                .padding(4)
                            })
                            VStack{
                                HStack{
                                    Spacer()
                                    Text(task.name)
                                    Spacer()
                                }
                                Text(task.description)
                                    .lineLimit(2,reservesSpace: true)
                                    .font(.footnote)
                                HStack{
                                    Text("\(Double(task.contractedRate)/100, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                        .font(.footnote)
                                    Spacer()
                                    Text(displaySecondsAsTime(seconds: task.estimatedTime))
                                        .font(.footnote)
                                }
                            }
                        }
                        .modifier(ListButtonModifier())
                        .padding(4)
                    }
                }
            }
        }
        .padding(4)
        .padding(.horizontal,4)
    }
}
    //#Preview {
    //    AddTaskGroupToJob()
    //}
