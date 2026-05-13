//
//  ServiceStopTaskView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/18/24.
//

import SwiftUI
@MainActor
final class ServiceStopTaskViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showAlert : Bool = false
    @Published var alertMessage:String = ""
    func finishServiceStopTask(companyId:String, serviceStop: ServiceStop, task: ServiceStopTask, status: JobTaskStatus)async throws {
        try await dataService.updateServiceStopTaskStatus(companyId: companyId, serviceStopId: serviceStop.id, taskId: task.id, status: status)
        if serviceStop.otherCompany {
            if let mainCompanyId = serviceStop.mainCompanyId {
                if serviceStop.jobId != "" {
                    //Update Sender Job
                    try dataService.updateJobTaskStatus(companyId: mainCompanyId, jobId: serviceStop.jobId, taskId: task.jobTaskId, status: .finished)
                } else {
                    //Update Sender RSS

                }
            }
        } else {
            //Update current company Job
            try dataService.updateJobTaskStatus(companyId: companyId, jobId: serviceStop.jobId, taskId: task.jobTaskId, status: .finished)
            
            //Update current company RSS

        }
        //Update Sender Labor Contract?

        //Update Sender Service Stop ?
        //Call Send Finish Email
    }
    func unfinishServiceStopTask(companyId:String, serviceStop: ServiceStop, task: ServiceStopTask, status: JobTaskStatus)async throws {
        try await dataService.updateServiceStopTaskStatus(companyId: companyId, serviceStopId: serviceStop.id, taskId: task.id, status: status)
        if serviceStop.otherCompany {
            if let mainCompanyId = serviceStop.mainCompanyId {
                if serviceStop.jobId != "" {
                    //Update Sender Job
                    try dataService.updateJobTaskStatus(companyId: mainCompanyId, jobId: serviceStop.jobId, taskId: task.jobTaskId, status: .scheduled)

                } else {
                    //Update Sender RSS

                }
            }
        } else {
            //Update current company Job
            try dataService.updateJobTaskStatus(companyId: companyId, jobId: serviceStop.jobId, taskId: task.jobTaskId, status: .scheduled)
            
            //Update current company RSS

        }
        //Update Sender Labor Contract?

        //Update Sender Service Stop ?
        //Call Send Finish Email
    }
}

struct ServiceStopTaskView: View {
    init(dataService:any ProductionDataServiceProtocol,taskList:Binding<[ServiceStopTask]>,serviceStopId:String) {
        _VM = StateObject(wrappedValue: ServiceStopTaskViewModel(dataService: dataService))
        self._taskList = taskList
        _serviceStopId = State(wrappedValue: serviceStopId)
    }
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataService : MasterDataManager
    @EnvironmentObject var navigationManager : NavigationStateManager

    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel
    
    @StateObject var VM : ServiceStopTaskViewModel

    @State var serviceStopId: String
    @Binding var taskList: [ServiceStopTask]
    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            if let serviceStop {
            VStack(spacing:0){
                HStack{
                    Spacer()
                    Text("Task List")
                        .font(.title3)
                    Spacer()
                }
                .padding(.vertical,8)
                .background(Color.darkGray.opacity(0.5))
                List{
                    ForEach($taskList) { $task in
                        ServiceStopTaskCardView(dataService: dataService, task: $task, serviceStop: serviceStop)
                            .listRowBackground(Color.listColor)

                            .swipeActions(edge: .trailing) {
                                Button {
                                    Task{
                                        if let currentCompany = masterDataService.currentCompany {
                                            do {
                                                //Update Data Base
                                                try await VM.finishServiceStopTask(companyId: currentCompany.id, serviceStop: serviceStop, task: task, status: .finished)
                                                //Update TaskId
                                                task.status = .finished
                                            } catch {
                                                print("Error")
                                                print(error)
                                            }
                                        }
                                    }
                                } label: {
                                    Label("Finish", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.poolGreen)
                            }
                            .swipeActions(edge:.leading) {
                                  Button {
                                      Task{
                                          if let currentCompany = masterDataService.currentCompany {
                                              
                                              do {
                                                //Update Data Base
                                                try await VM.unfinishServiceStopTask(companyId: currentCompany.id, serviceStop: serviceStop, task: task, status: .scheduled)
                                                  
                                                //Update TaskId
                                                task.status = .scheduled
                                              } catch {
                                                  print("Error")
                                                  print(error)
                                              }
                                          }
                                      }
                                  } label: {
                                      Label("Unfinish", systemImage: "xmark")
                                  }
                                  .tint(.poolRed)
                              }
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal,8)
            }
            .disabled(vm.activeRoute?.status != .inProgress)
            .disabled(serviceStop.startTime == nil)
                if let activeRoute = vm.activeRoute {
                    if activeRoute.status == .didNotStart || activeRoute.status == .onBreak || activeRoute.status == .traveling || activeRoute.status == .finished {
                        Button(action: {
                            vm.startActiveRoute(companyId: masterDataService.currentCompany?.id, companyName: masterDataService.currentCompany?.name, user: masterDataService.user)
                        }, label: {
                            Text("Start Route to Continue")
                                .font(.caption2)
                                .bold()
                                .padding(6)
                                .background(Color.orange.opacity(0.9))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding()
                                .accessibilityHidden(true)
                            
                        })
                    } else {
                        if serviceStop.startTime == nil {
                            Button(action: {
                                vm.startServiceStop(companyId: masterDataService.currentCompany?.id, serviceStopId:serviceStop.id)
                            }, label: {
                                Text("Start Service Stop To Continue")
                                    .font(.caption2)
                                    .bold()
                                    .padding(6)
                                    .background(Color.orange.opacity(0.9))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .padding()
                                    .accessibilityHidden(true)
                                
                            })
                            
                        }
                    }
                }
            }
        }
    }
}

//struct ServiceStopTaskView_Previews: PreviewProvider {
//    static var previews: some View {
//        ServiceStopTaskView(serviceStop: MockDataService.mockServicestop, taskList: [])
//    }
//}
extension ServiceStopTaskView {
    private func completeAction() -> some View {
           Button {
               // Handle mark as done action
           } label: {
               VStack {
                   Image(systemName: "checkmark.circle.fill")
                   Text("Mark Done")
               }
           }
           .tint(.green)
       }
       
       private func deleteAction() -> some View {
           Button(role: .destructive) {
               // Handle delete action
           } label: {
               VStack {
                   Image(systemName: "wrongwaysign.fill")
                   Text("Delete")
               }
           }
           .tint(.red)
       }
       
       private func editAction() -> some View {
           Button {
               // Handle edit action
           } label: {
               VStack {
                   Image(systemName: "note.text")
                   Text("Edit")
               }
           }
           .tint(Color(red: 255/255, green: 128/255, blue: 0/255))
       }
}
