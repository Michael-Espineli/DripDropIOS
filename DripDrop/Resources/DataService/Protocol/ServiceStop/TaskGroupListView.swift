//
//  TaskGroupListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import SwiftUI

@MainActor
final class TaskGroupListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showNewTaskGroup : Bool = false
    @Published private(set) var taskGroupList : [JobTaskGroup] = []
    func onLoad(companyId:String){
        Task{
            do {
                self.taskGroupList = try await dataService.getAllTaskGroups(companyId: companyId)
            } catch {
                print(error)
            }
        }
    }
}
struct TaskGroupListView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : TaskGroupListViewModel
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: TaskGroupListViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            VStack{
                if !UIDevice.isIPhone {
                    buttons
                }
                ScrollView{
                    list
                }
            }
            
            .padding(8)
            if UIDevice.isIPhone {
                icons
            }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id)
            }
        }
    }
}

#Preview {
    TaskGroupListView(dataService: MockDataService())
}
 
extension TaskGroupListView {
    var list : some View {
        VStack{
            ForEach(VM.taskGroupList){ group in
                if UIDevice.isIPhone {
//                    NavigationLink(value: Route.taskGroupDetail(dataService: dataService, taskGroup: group), label: {
                        TaskGroupCardView(taskGroup: group)
                    
//                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedTaskGroup = group
                    }, label: {
                        TaskGroupCardView(taskGroup: group)
                    })
                }
            }
        }
    }
    var buttons : some View {
        VStack{
            HStack{
                Button(action: {
                    VM.showNewTaskGroup.toggle()
                }, label: {
                    Text("Add")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $VM.showNewTaskGroup, onDismiss: {
                    if let currentCompany = masterDataManager.currentCompany {
                        VM.onLoad(companyId: currentCompany.id)
                    }
                }, content: {
                    AddNewTaskGroup(dataService: dataService)
                })
                Spacer()
            }
        }
    }
    var icons : some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        VM.showNewTaskGroup.toggle()
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(Color.poolRed)
                    })
                    .fullScreenCover(isPresented: $VM.showNewTaskGroup, onDismiss: {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.onLoad(companyId: currentCompany.id)
                        }
                    }, content: {
                        ZStack{
                            Color.listColor.ignoresSafeArea()
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        VM.showNewTaskGroup.toggle()
                                    }, label: {
                                        Image(systemName: "xmark")
                                            .modifier(DismissButtonModifier())
                                    })
                                }
                                .padding(8)
                                AddNewTaskGroup(dataService: dataService)
                            }
                        }
                    })
                }
                .padding(16)
            }
        }
    }
}
