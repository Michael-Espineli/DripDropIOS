//
//  ServiceStopFieldView.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/30/26.
//

import SwiftUI

struct ServiceStopFieldView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataService : MasterDataManager
    @StateObject var VM : ServiceStopTaskViewModel

    init(dataService:any ProductionDataServiceProtocol,taskList:Binding<[ServiceStopTask]>,serviceStop:ServiceStop) {
        _VM = StateObject(wrappedValue: ServiceStopTaskViewModel(dataService: dataService))
        self._taskList = taskList
        _serviceStop = State(wrappedValue: serviceStop)
    }
    
    @State var serviceStop: ServiceStop
    @Binding var taskList: [ServiceStopTask]
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
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
        }
    }
}

//struct ServiceStopTaskView_Previews: PreviewProvider {
//    static var previews: some View {
//        ServiceStopTaskView(serviceStop: MockDataService.mockServicestop, taskList: [])
//    }
//}
extension ServiceStopFieldView {
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
