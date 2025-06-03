//
//  AddNewScheduleServiceStopToNewJobView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//


import MapKit
import SwiftUI

struct AddNewScheduleServiceStopToNewJobView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : ScheduleServiceStopViewModel
    @State var jobId:String
    @State var customerId:String
    @State var customerName:String
    
    @State var serviceLocationId:String
    @State var description:String
    @State var jobTaskList:[JobTask]
    @Binding var serviceStops:[ServiceStop]
    @Binding var serviceStopTasks:[ServiceStop:[ServiceStopTask]]

    init(
        dataService:any ProductionDataServiceProtocol,
        jobId:String,
        customerId:String,
        customerName:String,
        serviceLocationId:String,
        description:String,
        jobTaskList:[JobTask],
        serviceStops:Binding<[ServiceStop]>,
        serviceStopTasks:Binding<[ServiceStop:[ServiceStopTask]]>
        
    ){
        _VM = StateObject(wrappedValue: ScheduleServiceStopViewModel(dataService: dataService))
        _jobId = State(wrappedValue: jobId)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _description = State(wrappedValue: description)
        _jobTaskList = State(wrappedValue: jobTaskList)
        self._serviceStops = serviceStops
        self._serviceStopTasks = serviceStopTasks

    }
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            formView
                .padding(8)
            if VM.isLoading {
                VStack{
                    ProgressView()
                    Text("Loading...")
                }
                .padding(8)
                .background(Color.gray)
                .cornerRadius(8)
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    VM.description = description
                    try await VM.onLoad(companyId: currentCompany.id, serviceLocationId: serviceLocationId, description: description,jobTaskList:jobTaskList)
                } catch {
                    print(error)
                }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: VM.serviceDate, perform: { date in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedUser, perform: { user in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedJobTaskList, perform: { tasks in
            VM.estimateTime(tasks: tasks)
            
        })
    }
}

    //#Preview {
    //    ScheduleServiceStopView(jobId: "", description: "")
    //}

extension AddNewScheduleServiceStopToNewJobView {
    var formView : some View {
        ScrollView{
            
            HStack{
                Text("Employee : ")
                    .bold(true)
                Picker("Employee", selection: $VM.selectedUser) {
                    Text("Select User").tag(CompanyUser(
                        id : "",
                        userId : "",
                        userName : "",
                        roleId : "",
                        roleName : "",
                        dateCreated :Date(),
                        status : .active,
                        workerType : .notAssigned
                    ))
                    ForEach(VM.companyUserList){ type in
                        Text("\(type.userName) \(type.roleName)").tag(type)
                        
                    }
                }
                .frame(maxWidth: .infinity)
            }
            DatePicker("Service Date", selection: $VM.serviceDate, in: Date()...,displayedComponents: .date)
                .bold()
            HStack{
                Text("Description:")
                    .bold(true)
                TextField(
                    "Description",
                    text: $VM.description
                )
                .padding(.leading,4)
                .padding(4)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .padding(4)
            }
            
            HStack{
                Text("Estimated Time:")
                    .bold(true)
                Text(displayMinAsMinAndHour(min: VM.estimatedTime))

            }
            Rectangle()
                .frame(height: 1)
            HStack{
                Button(action: {
                    VM.showRouteSnapShot.toggle()
                }, label: {
                    if VM.showRouteSnapShot {
                        Text("Collapse")
                            .foregroundColor(Color.poolBlue)
                        
                    } else  {
                        Text("Expand")
                            .foregroundColor(Color.poolRed)
                    }
                })
                .sheet(isPresented: $VM.showRouteSnapShot, content: {
                    VStack{
                        Text("Show Route Snap Shot")
                            .font(.headline)
                        Rectangle()
                            .frame(height: 1)
                        HStack{
                            Text("Stops: ")
                                .bold()
                            Spacer()
                            Text("\(String(VM.finishedStops))/\(String(VM.totalStops))")
                        }
                        Text("If Clocked in: 5 Hours")
                        
                        HStack{
                            Text("Status: ")
                                .bold()
                            Spacer()
                            Text("\(VM.routeStatus)")
                        }
                        
                        HStack{
                            Text("Estimated Time: ")
                                .bold()
                            Spacer()
                            Text("\(displayMinAsMinAndHour(min: VM.estimatedTimeMin)) hrs")
                        }
                        
                        HStack{
                            Text("Estimated Milage: ")
                                .bold()
                            Spacer()
                            Text("\(String(VM.estimatedTimeMiles)) mi")
                        }
                        Spacer()
                    }.padding(8)
                    .presentationDetents([.fraction(0.4)])
                })
                Spacer()
                Text("Route Snap Shot For User and Day")
            }
            Rectangle()
                .frame(height: 1)
            Text("Select Tasks List")
                .font(.headline)
            Divider()
            ForEach(VM.jobTaskList){ type in
                switch type.status{
                case .accepted, .offered, .scheduled, .finished, .inProgress:
                    HStack{
                        Spacer()
                        Text("\(type.type) - \(type.status.rawValue) : \(type.name)")
                            .lineLimit(1)
                    }
                    .modifier(ListButtonModifier())
                    .opacity(0.5)
                case .unassigned, .rejected, .draft:
                    
                    Button(action: {
                        if VM.selectedJobTaskList.contains(where: {$0.id == type.id}) {
                            VM.selectedJobTaskList.removeAll(where: {$0.id == type.id})
                        } else {
                            VM.selectedJobTaskList.append(type)
                        }
                    }, label: {
                        HStack{
                            if VM.selectedJobTaskList.contains(where: {$0.id == type.id}) {
                                Image(systemName: "checkmark.square")
                                    .lineLimit(1)
                            } else {
                                Image(systemName: "square")
                            }
                            Spacer()
                            Text("\(type.type) - \(type.status.rawValue) : \(type.name)")
                                .lineLimit(1)
                        }
                    })
                        //                    .modifier(VM.selectedJobTaskList.contains(where: {$0.id == type.id}) ? SubmitButtonModifier(): ListButtonModifier())
                    .modifier(ListButtonModifier())
                }
                
            }
            
            Button(action: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            let values = try await VM.scheduleNewServiceStopNewJob(
                                companyId: currentCompany.id,
                                jobId: jobId,
                                customerId: customerId,
                                customerName: customerName,
                                serviceLocationId: serviceLocationId
                            )
                            serviceStops.append(values.0)
                            
                            serviceStopTasks[values.0] = values.1
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                }
            },
                   label: {
                HStack{
                    Spacer()
                    Text("Schedule New Service Stop")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())
            })
            .disabled(VM.isLoading)
            .opacity(VM.isLoading ? 0.75 : 1)
        }
    }
}
