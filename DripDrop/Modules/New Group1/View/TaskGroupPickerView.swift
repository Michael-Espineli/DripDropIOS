    //
    //  TaskGroupPickerView.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/9/24.
    //

import SwiftUI
@MainActor
final class TaskGroupPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var taskGroupList : [JobTaskGroup] = []
    @Published private(set) var taskGroupItems : [JobTaskGroupItem] = []
    
    @Published var selectedTaskGroup : JobTaskGroup? = nil
    func onload(companyId:String) {
        Task{
            do {
                self.taskGroupList = try await dataService.getAllTaskGroups(companyId: companyId)
            } catch {
                print(error)
            }
        }
    }
    func onChangeOfTaskGroup(companyId:String) {
        if let selectedTaskGroup {
            Task{
                do {
                    self.taskGroupItems = try await dataService.getAllTaskGroupItems(companyId: companyId, taskGroupId: selectedTaskGroup.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}
struct TaskGroupPickerView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : TaskGroupPickerViewModel
    @Binding var tasks : [JobTaskGroupItem]
    init(dataService : any ProductionDataServiceProtocol, tasks:Binding<[JobTaskGroupItem]>){
        _VM = StateObject(wrappedValue: TaskGroupPickerViewModel(dataService: dataService))
        self._tasks = tasks
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Task Group Picker")
                if VM.selectedTaskGroup != nil{
                    detail
                } else {
                    list
                }
            }
            .padding(8)
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onload(companyId: currentCompany.id)
            }
        }
        .onChange(of: VM.selectedTaskGroup, perform: { datum in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChangeOfTaskGroup(companyId: currentCompany.id)
            }
        })
    }
}

    //#Preview {
    //    TaskGroupPickerView()
    //}
extension TaskGroupPickerView {
    var list: some View {
        VStack{
            ForEach(VM.taskGroupList){ group in
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
                            .font(.footnote)
                        Text(String(group.numberOfTasks))
                            .font(.footnote)
                    }
                    .modifier(ListButtonModifier())
                })
            }
        }
    }
    var detail: some View {
        VStack{
            HStack{
                Button(action: {
                    VM.selectedTaskGroup = nil
                }, label: {
                    Text("Back")
                        .modifier(DismissButtonModifier())
                })
                Spacer()
                Button(action: {
                    tasks = VM.taskGroupItems
                }, label: {
                    Text("Select Group")
                        .modifier(SubmitButtonModifier())
                })
            }
            if let selectedTaskGroup = VM.selectedTaskGroup {
                Text(selectedTaskGroup.name)
            }
            ForEach(VM.taskGroupItems){ item in
                HStack{
                    Spacer()
                    Text(item.name)
                    Spacer()
                }
                .modifier(ListButtonModifier())
            }
        }
    }
}
